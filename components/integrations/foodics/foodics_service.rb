module Integrations
  module Foodics
    class FoodicsService < Base::ServiceInterface
      def initialize(integration_host)
        super(integration_host)

        config = {
          base_url: integration_host.config["base_url"],
          secret: integration_host.config["secret"],
          business_id: integration_host.config["business_id"],
        }

        @client = Integrations::Foodics::Client.new(config: config)
      end

      def sync_stores
        branches = branches_accepting_delivery_orders

        integration_stores = branches.map { |branch|
          {
            external_reference: branch["hid"],
            external_data: branch,
          }
        }

        persist_stores(integration_stores)

        true
      end

      def sync_store_statuses
        branches = branches_accepting_delivery_orders

        ready_stores_external_references =
          branches.select { |branch| branch_available?(branch) }
            .map { |branch| branch["hid"] }

        busy_stores_external_references =
          branches.reject { |branch| branch_available?(branch) }
            .map { |branch| branch["hid"] }

        # Get the store IDs of all stores tied to the integration store by
        # external reference
        store_ids_to_make_ready =
          Integrations::IntegrationStore.where(
            external_reference: ready_stores_external_references,
            enabled: true,
            integration_host_id: @integration_host.id,
          ).where.not(store_id: nil).pluck(:store_id)

        store_ids_to_make_busy =
          Integrations::IntegrationStore.where(
            external_reference: busy_stores_external_references,
            enabled: true,
            integration_host_id: @integration_host.id,
          ).where.not(store_id: nil).pluck(:store_id)

        # Publish new store statuses
        if store_ids_to_make_ready && store_ids_to_make_ready.length > 0
          publish_store_statuses(
            store_ids: store_ids_to_make_ready,
            status: Stores::StoreStatus.statuses[:ready]
          )
        end

        if store_ids_to_make_busy && store_ids_to_make_busy.length > 0
          publish_store_statuses(
            store_ids: store_ids_to_make_busy,
            status: Stores::StoreStatus.statuses[:temporary_busy]
          )
        end
      end

      def sync_catalog_list
        # Foodics does not really have a concept of a catalog list, it just has
        # a catalog, so we are simply persisting the integration_catalog for
        # consistency's sake.
        integration_catalog = {external_reference: nil}
        persist_catalog_list([integration_catalog])

        true
      end

      # TODO: DOME-339 Handle `special_branch_prices` and `taxable`
      def sync_catalog(integration_catalog:)
        catalog = @client.catalog
        adapter = Integrations::Foodics::Adapters::CatalogAdapter.new(catalog)
        catalog = adapter.adapt

        integration_catalog.external_data = catalog
        integration_catalog.save

        if integration_catalog.catalog
          serializer = Serializers::FirestoreCatalogSerializer.new(
            catalog: catalog,
            tax_rate: tax_rate
          )
          catalog = serializer&.menu

          image_syncer = Integrations::ImageSyncer.new(firestore_catalog: catalog)
          synced_catalog = image_syncer.sync

          overridden_catalog = Integrations::IntegrationCatalogOverrideService.apply_overrides(
            integration_catalog_id: integration_catalog.id,
            catalog: synced_catalog,
          )

          mapped_catalog = IdNumberifier.new.firestore_catalog(overridden_catalog)

          persist_catalog_on_firstore(
            integration_catalog: integration_catalog,
            serialized_catalog: mapped_catalog
          )
        end

        true
      end

      def sync_out_of_stock_items
        IntegrationStore.where(integration_host_id: @integration_host.id, enabled: true)
          .where.not(store_id: nil).each do |integration_store|
          inactive_items = @client.inactive_items(branch_hid: integration_store.external_reference)
            .dig("inactive_items")

          next unless inactive_items

          # These are HIDs (Foodics format)
          # TODO: DOME-340 Handle inactive categories and modifiers. These
          #       require re-publishing the catalog.
          #       (there are also tags but we don't use them)
          out_of_stock_item_hids = inactive_items["products"] +
            inactive_items["sizes"]

          # These are IDs (Dome format)
          out_of_stock_item_ids = out_of_stock_item_hids.map { |hid|
            IdNumberifier.new.id_of(hid)
          }

          item_availability_service = StoreItemAvailabilities::StoreItemAvailabilityService.new

          item_availability_service.mark_out_of_stock(
            store_id: integration_store.store_id,
            item_ids: out_of_stock_item_ids
          )
        end
      end

      def create_order(order:)
        integration_store = @integration_host.integration_stores
          .find_by(store_id: order.store_id)

        integration_catalog = @integration_host&.integration_catalogs&.last

        order = IdNumberifier.new.order(order)
        data = Params::OrderCreationParams.new(
          order: order,
          integration_store: integration_store,
          catalog: integration_catalog,
        ).build

        foodics_order = @client.create_order(data)
        foodics_order_id = foodics_order["order_hid"]

        unless foodics_order_id
          raise Base::Errors::FailedToCreateOrderError.new(
            "Failed to create order with backend ID on Foodics #{order_id}",
            {
              order: order,
              response: foodics_order,
              integration_host_id: @integration_host.id,
            }
          )
        end

        integration_order = {
          order_id: order.id,
          external_reference: foodics_order_id,
          external_data: foodics_order,
        }

        persist_order(integration_order)
      end

      def sync_order_status(integration_order:)
        order_hid = integration_order.external_reference

        return unless order_hid

        foodics_order = @client.order(order_hid)&.dig("order")

        return unless foodics_order

        order_status_serializer = Serializers::OrderStatusSerializer.new(
          order: foodics_order
        )

        order_status = order_status_serializer.serialize

        status = order_status[:status]
        mapped_status = OrderStatus.mapped_status(status)

        update_order_status(
          integration_order,
          status,
          mapped_status,
          order_status
        )
      end

      private

      def branches_accepting_delivery_orders
        branches = @client.branches

        return [] if branches.nil?

        branches.select { |branch|
          branch["accepts_online_orders"] &&
            Helpers::Branch.branch_accepts_delivery?(
              branch_disabled_order_types: branch["disabled_order_types"]
            )
        }
      end

      def tax_rate
        business = @client.current_business

        unless business
          raise new Integrations::Foodics::Errors::UnableToFetchBusinessError.new(
            "Foodics - Unable to fetch business",
            {business_id: @business_id}
          )
        end

        return BigDecimal(0) if business["prices_include_taxes"]

        # TODO: Find out why this is an array, we've only ever seen it have 1
        # element.
        taxes = @client.taxes
        tax = taxes&.first

        return BigDecimal(0) unless tax&.key?("amount")

        # tax["amount"] will be an integer 5 for Saudi Arabia as of
        # September 2019
        BigDecimal(tax["amount"]) / BigDecimal(100)
      end

      def branch_available?(foodics_branch)
        # These are integeres which are basically hours of the day in 24H
        # format, They can be empty strings, but `to_i` will turn those into 0.
        opening_hour = foodics_branch["open_from"].to_i
        closing_hour = foodics_branch["open_till"].to_i

        # Handle the simple case where closing hour is less than opening hour,
        # meaning closing hour is in the next day
        return true if closing_hour < opening_hour

        # This will be either a negative/positive float as a string, which we
        # convert to a float ourselves (We use "3.000" to match the way they
        # return it).
        utc_offset = (foodics_branch.dig("city", "timezone") || "3.000").to_f
        time_zone = ActiveSupport::TimeZone[utc_offset]

        current_hour = time_zone.now.hour

        current_hour >= opening_hour && current_hour < closing_hour
      end
    end
  end
end
