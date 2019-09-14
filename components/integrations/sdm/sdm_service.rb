module Integrations
  module Sdm
    # TODO: Perhaps break this up into several classes that inherit from
    # SDM Service, each dealing with a specific area. e.g. SDMOrderingService,
    # SDMCatalogService, and so on.
    class SdmService < Base::ServiceInterface
      attr_reader :client

      def initialize(integration_host)
        super(integration_host)
        config = {
          wsdl_url: integration_host.config["wsdl_url"],
          license_code: integration_host.config["license_code"],
        }

        @source = integration_host.config["source"]
        @concept_id = integration_host.config["concept_id"]
        @client = Integrations::Sdm::Client.new(config: config)
        @payment_config = {
          cash: {
            sub_type: integration_host.config["cash_sub_type"],
            tender_id: integration_host.config["cash_tender_id"],
          },
          prepaid: {
            sub_type: integration_host.config["prepaid_sub_type"],
            tender_id: integration_host.config["prepaid_tender_id"],
          },
        }
      end

      def sync_stores
        stores = @client.get_stores_list(concept_id: @concept_id)
        integration_stores = stores.map { |store|
          {
            external_reference: store[:str_id],
            external_data: store,
          }
        }

        persist_stores(integration_stores)
        true
      end

      def sync_catalog_list
        menu_templates = @client.get_menu_templates_list(concept_id: @concept_id)
        integration_catalogs = []
        menu_templates&.each do |menu_template|
          # HACK: Due to the way the SOAP response is returned and how our
          # serializer handles it, 'named arrays' get turned into an array
          # of arrays, which maps to first.last in our case
          menu_template[:menus]&.first&.last&.each do |menu|
            menu_template_id = menu_template[:menu_id]
            menu_id = menu[:key]

            integration_catalogs << {
              # HACK: Since our external reference is a string, store both
              # menu template ID and menu ID (we need both) as a dash-separated
              # ID (mtID-mID). We only store this to have the reference, but
              # we actually use external_data.menu_template_id and
              # external_data.menu_id
              external_reference: menu_template_id + "-" + menu_id,
              external_data: {
                menu_template_id: menu_template_id,
                menu_id: menu_id,
              },
            }
          end
        end

        persist_catalog_list(integration_catalogs)
      end

      def sync_catalog(integration_catalog:)
        menu_template_id = integration_catalog
          .external_data&.dig("menu_template_id")

        menu_id = integration_catalog.external_data&.dig("menu_id")

        return if menu_template_id.nil? || menu_id.nil?

        submenus = get_submenus(
          menu_template_id: menu_template_id,
          menu_id: menu_id
        )

        items = get_items(
          submenus: submenus,
          menu_template_id: menu_template_id
        )

        modifier_groups = get_modifier_groups(
          items: items,
          menu_template_id: menu_template_id
        )

        modifiers = get_modifiers(
          modifier_groups: modifier_groups,
          menu_template_id: menu_template_id
        )

        external_data = {
          submenus: submenus,
          items: items,
          modifier_groups: modifier_groups,
          modifiers: modifiers,
        }

        integration_catalog.external_data = integration_catalog.external_data.merge(external_data)
        integration_catalog.save

        serialize_and_publish_catalog(integration_catalog: integration_catalog)
        true
      end

      def create_order(order:)
        order_dto = order
        integration_store = get_integration_store(order_dto: order_dto)
        return if integration_store.nil?

        sdm_customer = get_or_create_sdm_customer(
          customer_dto: order_dto&.customer,
          customer_address_dto: order_dto&.customer_address,
          integration_store: integration_store
        )

        return if sdm_customer.nil?

        integration_catalog = get_integration_catalog(order_dto: order_dto)

        return if integration_catalog.nil?

        # Numberify order (TODO: Explain what this does)
        order_dto = IdNumberifier.new.order(order_dto)

        sdm_order = serialize_order(
          order_dto: order_dto,
          sdm_customer: sdm_customer,
          integration_store: integration_store,
          integration_catalog: integration_catalog
        )

        begin
          sdm_order_id = @client.create_order(sdm_order: sdm_order)

          if sdm_order_id
            integration_order = {
              order_id: order_dto.id,
              external_reference: sdm_order_id,
              external_data: {},
            }

            return persist_order(integration_order)
          end
        rescue Sdm::Errors::OutOfWorkingHoursError => e # Prayer times
          # The order creator worker will keep retrying when this error is raised
          raise Base::Errors::TemporaryUnavailableError.new(
            "Integration store #{integration_store.id} is temporarily unavailable, retrying order #{order_dto.id}",
              nil
          )
        rescue Base::Errors::ApiError, Sdm::Errors::FailedToCreateOrderError => e
          Raven.capture_exception(e, extra: {order: order_dto})
          return reject_order(order_dto)
        end
      end

      def sync_order_status(integration_order:)
        order_data = @client.get_order_details(
          order_id: integration_order.external_reference
        )

        order_status = order_data&.dig(:status)

        if order_status
          mapped_status = Mappers::OrderStatus.mapped_status(order_status)

          update_order_status(
            integration_order,
            order_status,
            mapped_status,
            order_data
          )
        end
      end

      private

      def get_submenus(menu_template_id:, menu_id:)
        @client.get_submenus_list(
          concept_id: @concept_id,
          menu_template_id: menu_template_id,
          menu_id: menu_id
        )
      end

      def get_items(submenus:, menu_template_id:)
        threads = number_of_threads_for_syncing

        Parallel.map(submenus, in_threads: threads) { |submenu|
          @client.get_items_list(
            concept_id: @concept_id,
            menu_template_id: menu_template_id,
            submenu_id: submenu[:id]
          )
        }.flatten.uniq { |item| item[:id] }
      end

      def get_modifier_groups(items:, menu_template_id:)
        threads = number_of_threads_for_syncing

        Parallel.map(items, in_threads: threads) { |item|
          @client.get_modgroups_list(
            concept_id: @concept_id,
            menu_template_id: menu_template_id,
            item_id: item[:id]
          )
        }.flatten.uniq { |modifier_groups| modifier_groups[:id] }
      end

      def get_modifiers(modifier_groups:, menu_template_id:)
        threads = number_of_threads_for_syncing

        Parallel.map(modifier_groups, in_threads: threads) { |modifier_group|
          @client.get_modifiers_list(
            concept_id: @concept_id,
            menu_template_id: menu_template_id,
            modgroup_id: modifier_group[:id]
          )
        }.flatten
      end

      def get_integration_store(order_dto:)
        IntegrationStore.find_by(
          store_id: order_dto.store_id,
          integration_host_id: @integration_host.id
        )
      end

      def get_integration_catalog(order_dto:)
        catalog_id = Catalogs::CatalogAssignmentService.new.related_to(
          related_to_id: order_dto.store.id,
          related_to_type: "Stores::Store"
        )&.catalog_id

        if catalog_id.nil?
          catalog_id = Catalogs::CatalogAssignmentService.new.related_to(
            related_to_id: order_dto.store.brand_id,
            related_to_type: "Brands::Brand"
          )&.catalog_id
        end

        IntegrationCatalog.find_by(catalog_id: catalog_id)
      end

      # @param [CustomerDTO] customer_dto The customer data transfer object
      # @param [Hash] integration_store The store to use to register its address as the customer's address
      # @return [SdmCustomer, nil] An Sdm::Models::SdmCustomer or nil
      def get_or_create_sdm_customer(
        customer_dto:,
        integration_store:,
        customer_address_dto:
      )
        return if customer_dto.nil? || customer_dto.phone_number.nil?

        # Format mobile to local format (e.g. 0501234567), SDM requires this
        # format.
        locally_formatted_mobile = Customers::MobileHelper.format_to(
          mobile: customer_dto.phone_number,
          format: :national
        )

        # Find customer on SDM (use local mobile format since SDM expects
        # that)
        sdm_customer = get_customer(mobile: locally_formatted_mobile)

        # All of these branches should also return the same return types as
        # this method's return type
        if sdm_customer.is_not_registered? || sdm_customer.should_be_recreated?
          create_customer(
            customer_dto: customer_dto,
            customer_address_dto: customer_address_dto,
            mobile: locally_formatted_mobile,
            integration_store: integration_store
          )
        elsif sdm_customer.has_no_address?
          # We can't create orders for customers without addresses, so we have
          # to make an address for them if they don't have one
          register_address_for_customer(
            customer_id: sdm_customer.id,
            customer_address_dto: customer_address_dto,
            mobile: locally_formatted_mobile,
            integration_store: integration_store
          )
        else
          sdm_customer
        end
      end

      # This method calls GetCustomerByMobile and then GetCustomerByID
      # because GetCustomerByMobile returns fake results. A customer ID you get
      # back from GetCustomerByMobile when passed to GetCustomerByID returns a
      # CustomerDoesNotExist error. We'll rely on GetCustomerByID as our source
      # of truth.
      # @return [SdmCustomer] An Sdm::Models::SdmCustomer
      def get_customer(mobile:)
        # Find customer on SDM (use local mobile format since SDM expects
        # that)
        customer = @client.get_customer_by_mobile(
          concept_id: @concept_id,
          mobile: mobile
        )

        sdm_customer = Integrations::Sdm::Models::SdmCustomer.new(customer)

        if sdm_customer.id
          customer = @client.get_customer_by_id(
            concept_id: @concept_id,
            id: sdm_customer.id
          )

          Integrations::Sdm::Models::SdmCustomer.new(customer)
        else
          sdm_customer
        end
      end

      # @return [SdmCustomer, nil] An Sdm::Models::SdmCustomer or nil
      def create_customer(
        customer_dto:,
        customer_address_dto:,
        mobile:,
        integration_store:
      )
        return nil if customer_dto.nil? || mobile.nil? || integration_store.nil?

        customer = @client.create_customer(
          concept_id: @concept_id,
          customer_dto: customer_dto,
          mobile: mobile
        )

        created_customer_id = customer&.dig(:cust_id)

        if created_customer_id.nil?
          raise Integrations::Sdm::Errors::FailedToCreateCustomerError,
                "Failed to register SDM customer for customer ID: #{customer_dto.id}"
        end

        # Register address for customer. We have to do this because for
        # some reason SDM refuses to save addresses when sent with the register
        # request.
        register_address_for_customer(
          customer_id: created_customer_id,
          customer_address_dto: customer_address_dto,
          integration_store: integration_store,
          mobile: mobile
        )
      end

      # This method should only be called for existing SDM customers that do not
      # have an address.
      #
      # @param [String] customer_id The customer's ID on SDM
      # @param [Hash] integration_store The store to use to register its address as the customer's address
      # @return [SdmCustomer, nil] An Sdm::Models::SdmCustomer or nil
      def register_address_for_customer(
        customer_id:,
        customer_address_dto:,
        integration_store:,
        mobile:
      )
        return nil if customer_id.nil? || integration_store.nil?

        # TODO: When syncing stores is implemented, the integration_store should
        # have the address and we shouldn't need to make an API call here
        # HACK: Pass customer mobile and set it as integration store's address
        # because SDM needs the customer's address to have a phone number.
        integration_store_address = integration_store_address(
          integration_store: integration_store,
          mobile: mobile
        )

        customer_address = integration_store_address.to_sdm_customer_address(
          concept_id: @concept_id,
          latitude: customer_address_dto.latitude,
          longitude: customer_address_dto.longitude,
          customer_id: customer_id
        )

        customer = @client.register_customer_address(
          customer_id: customer_id,
          mobile: mobile,
          address: customer_address
        )

        serialized_customer = Integrations::Sdm::Models::SdmCustomer.new(customer)

        if serialized_customer.has_no_address?
          raise Integrations::Sdm::Errors::FailedToRegisterCustomerAddressError,
                "Failed to register SDM address for customer: #{customer_id}"
        end

        serialized_customer
      end

      def integration_store_address(integration_store:, mobile: nil)
        store_area = client.get_store_area(
          concept_id: @concept_id,
          store_id: integration_store.external_reference&.to_s
        )

        # We found a store, return its address
        if store_area && !store_area.empty?
          return Integrations::Sdm::Models::SdmAddress.new(
            hash: store_area,
            mobile: mobile
          )
        end

        # Try and use a default address if we have one
        integration_store_address = Integrations::Sdm::Models::Hacks.default_integration_store_address(
          name: @integration_host.name,
          mobile: mobile
        )

        # We didn't find a store, and we have no default address, which means
        # we can't make an order, raise an exception.
        if integration_store_address.nil?
          raise Integrations::Sdm::Errors::FailedToGetIntegrationStoreAddressError.new(
            "Failed to get to get address for integration store with SDM ID: #{integration_store.external_reference}",
            {
              integration_store: integration_store,
              integration_store_external_reference: integration_store.external_reference,
              integration_host_name: @integration_host.name,
              integration_host_id: @integration_host.id,
            }
          )
        end

        integration_store_address
      end

      def serialize_and_publish_catalog(integration_catalog:)
        return if integration_catalog.nil? || integration_catalog.catalog.nil?

        submenus = integration_catalog.external_data["submenus"]
        items = integration_catalog.external_data["items"]
        modifier_groups = integration_catalog.external_data["modifier_groups"]
        modifiers = integration_catalog.external_data["modifiers"]

        id_numberifier = Integrations::IdNumberifier.new

        serializer =
          Integrations::Sdm::Serializers::SdmToDome::CatalogSerializer.new(
            submenus: submenus,
            items: items,
            modifier_groups: modifier_groups,
            modifiers: modifiers,
            integration_catalog: integration_catalog,
          )

        mapped_catalog = serializer&.menu

        mapped_catalog = Integrations::IntegrationCatalogOverrideService.apply_overrides(
          integration_catalog_id: integration_catalog.id,
          catalog: mapped_catalog
        )

        mapped_catalog = id_numberifier.firestore_catalog(mapped_catalog)

        persist_catalog_on_firstore(
          integration_catalog: integration_catalog,
          serialized_catalog: mapped_catalog,
        )
      end

      def number_of_threads_for_syncing
        Rails.application.secrets.integrations[:number_of_threads_for_syncing]
      end

      def serialize_order(order_dto:, sdm_customer:, integration_store:, integration_catalog:)
        serializer = Integrations::Sdm::Serializers::DomeToSdm::OrderSerializer.new(
          order_dto: order_dto,
          customer_id: sdm_customer.id,
          concept_id: @concept_id,
          integration_store: integration_store,
          integration_catalog: integration_catalog,
          source: @source,
          address_id: sdm_customer.address_id,
          payment_config: @payment_config
        )

        serializer.serialize
      end
    end
  end
end
