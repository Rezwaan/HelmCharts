module Rush
  module Workers
    class KuduOrderPersister
      class StoreNotIntegrated < StandardError; end
      class SdmCustomerDoesNotExist < StandardError; end

      include Sidekiq::Worker

      sidekiq_options retry: 5

      # https://github.com/mperham/sidekiq/wiki/Ent-Unique-Jobs
      sidekiq_options unique_for: 10.minutes

      sidekiq_retry_in do |count, e|
        30 * (count + 1)
      end

      sidekiq_retries_exhausted do |msg, e|
        Sidekiq.logger.warn "Failed #{msg["class"]} with #{msg["args"]}: #{msg["error_message"]}"
      end

      PAYMENT_TYPES = {
        cash: 1,
        credit_card: 2,
      }

      def perform(sdm_order_id)
        throttle = Sidekiq::Limiter.window("integration-host-#{integration_host.id}", 60, :minute, wait_timeout: 5)
        throttle.within_limit do
          order = fetch_order(sdm_order_id)
          return unless order.present?

          update_last_checked_order_id(sdm_order_id)
          persist_order(order) unless from_allowed_source?(order)
        end
      end

      private

      def fetch_order(sdm_order_id)
        order = nil

        # TODO: Do we need to update orders?
        return if Orders::Order.where(platform_id: kudu_platform.id, backend_id: sdm_order_id).first.present?

        # rubocop:disable Style/GlobalVars
        $kudu_sdm_client.with do |client|
          order = client.get_order_details(order_id: sdm_order_id)
        end
        # rubocop:enable Style/GlobalVars

        order
      end

      def update_last_checked_order_id(sdm_order_id)
        # rubocop:disable Style/GlobalVars
        $redis.watch("rush:kudu:last_checked_order_id")
        last_checked_order_id = $redis.watch("rush:kudu:last_checked_order_id")
        $redis.multi do
          if last_checked_order_id < sdm_order_id
            # Update "rush:kudu:last_checked_order_id" in Redis.
            $redis.set("rush:kudu:last_checked_order_id", sdm_order_id)
          end
        end
        # rubocop:enable Style/GlobalVars
      end

      def persist_order(order)
        # We are assuming that each SDM order has a customer and store here.
        begin
          store = get_store(order: order)
        rescue StoreNotIntegrated => e
          Raven.capture_exception(e)
          # Do nothing
          return
        end

        begin
          order_dto = Orders::RushOrderService.new.create(attributes: {
            platform_id: kudu_platform.id,
            backend_id: order.dig(:order_id),
            payment: get_payment(order: order),
            line_items: get_items(order: order),
            customer: get_customer(order: order),
            store_id: store.dig(:id),
            currency: :sar,
          })
        rescue SdmCustomerDoesNotExist => e
          Raven.capture_exception(e)
          return
        rescue ActiveRecord::RecordNotUnique
          # Order already exists
          return
        end

        RushDeliveries::RushDeliveryService.new.create(attributes: {
          order_id: order_dto.id,
          drop_off_longitude: order_dto.customer_address.longitude,
          drop_off_latitude: order_dto.customer_address.latitude,
          drop_off_description: "",
          pick_up_longitude: store.dig(:longitude),
          pick_up_latitude: store.dig(:latitude),
        })
      end

      ALLOWED_SOURCE_IDS = {
        call_center: 1,
        web: 2,
        ios_app: 12,
        android_app: 13,
      }

      def from_allowed_source?(order)
        ALLOWED_SOURCE_IDS.value?(order.dig(:source).to_i)
      end

      ALLOWED_STORE_IDS = [49]

      def from_allowed_store?(order)
        ALLOWED_STORE_IDS.include? order.dig(:store_id)
      end

      def payment_type(payment)
        return "cash" if payment.nil?

        payment_type = PAYMENT_TYPES.key(payment.dig(:pay_type).to_i)
        return "prepaid" if payment_type == :credit_card

        payment_type.to_s
      end

      def get_customer(order:)
        customer_id = order.dig(:customer_id)

        customer = nil
        # rubocop:disable Style/GlobalVars
        $kudu_sdm_client.with do |client|
          customer = client.get_customer_by_id(
            concept_id: integration_host.config["concept_id"],
            id: customer_id,
          )
        end
        # rubocop:enable Style/GlobalVars

        if customer.nil?
          raise SdmCustomerDoesNotExist, "Customer: #{customer_id}"
        end

        # Find address details using order's address ID
        address = customer.dig(:addresses, :cc_address)
        if address.is_a?(Array)
          address_id = order.dig(:address_id)
          address = address.find { |a| address_id.to_s == a[:addr_id].to_s }
        end

        {
          id: customer.dig(:cust_id),
          name: "#{customer.dig(:cust_firstname)} #{customer.dig :cust_lastname}",
          address: {
            id: address.dig(:addr_id),
            longitude: address.dig(:addr_mapcode, :x),
            latitude: address.dig(:addr_mapcode, :y),
          },
          phone: {
            country_code: "966",
            number: customer.dig(:cust_phonelookup),
          },
        }
      end

      def get_store(order:)
        sdm_store_id = order.dig(:store_id)

        integration_store = Integrations::IntegrationStore.find_by!(
          external_reference: sdm_store_id,
          integration_host_id: integration_host.id,
        )

        if integration_store.store.nil?
          raise StoreNotIntegrated, "IntegrationStore: #{integration_store.id}"
        end

        {
          id: integration_store.store.id.to_s,
          latitude: integration_store.store.latitude,
          longitude: integration_store.store.longitude,
          brand: {
            id: integration_store.store.brand.id.to_s,
          },
        }
      end

      def collect_at_customer(order, payment)
        return order.dig(:total).to_f if payment.nil?

        order.dig(:total).to_f - payment.dig(:pay_amount).to_f
      end

      def get_payment(order:)
        payment = {
          amount: order.dig(:gross_total).to_f,
          discount: order.dig(:discount_total).to_f,
          delivery_fee: order.dig(:service_charge).to_f,
          collect_at_pickup: order.dig(:sub_total).to_f,
        }

        order_payment = order.dig(:payments, :cc_order_payment)
        if order.dig(:payments).is_a?(Array) && !order.dig(:payments).nil?
          order_payment = order_payment&.find { |p|
            p[:pay_ordrid].to_s == order.dig(:order_id).to_s
          }
        end

        payment[:payment_type] = payment_type(order_payment)
        payment[:collect_at_customer] = collect_at_customer(order, order_payment)

        payment
      end

      def get_quantity(elements:, item_id:)
        elements.count { |element| element.dig(:item_id) == item_id }
      end

      def has_element?(elements:, item_id:)
        elements.any? { |element| element.dig(:item_id) == item_id }
      end

      def get_modifiers(modifiers:)
        order_modifiers = []

        modifiers = Array.wrap(modifiers) unless modifiers.is_a?(Array)

        modifiers&.each do |modifier|
          next if has_element?(elements: order_modifiers, item_id: modifier.dig(:item_id))

          order_modifiers << {
            item_reference: modifier.dig(:item_id),
            quantity: get_quantity(elements: modifiers, item_id: modifier.dig(:item_id)),
            translations_attributes: [{
              local: "en",
              name: modifier.dig(:short_name),
              group: modifier.dig(:mod_code),
            }, {
              local: "ar",
              name: modifier.dig(:shortname_un) || modifier.dig(:short_name),
              group: modifier.dig(:mod_code),
            },],
          }
        end

        order_modifiers
      end

      def get_items(order:)
        order_items = []

        items = order.dig(:entries, :c_entry)
        items = Array.wrap(items) unless items.is_a?(Array)

        items&.each do |item|
          next if has_element?(elements: order_items, item_id: item.dig(:item_id))

          order_items << {
            backend_id: item.dig(:id),
            quantity: get_quantity(elements: items, item_id: item.dig(:item_id)),
            total_price: item.dig(:price),
            discount: item.dig(:discount_price),
            item_reference: item.dig(:item_id),
            item_detail: item,
            modifiers: get_modifiers(modifiers: item.dig(:entries, :c_entry)),
            translations_attributes: [{
              backend_id: item.dig(:id),
              locale: "en",
              name: item.dig(:name),
            }, {
              backend_id: item.dig(:id),
              locale: "ar",
              name: item.dig(:longname_un) || item.dig(:name),
            }, {
              backend_id: item.dig(:id),
              locale: "en",
              notes: item.dig(:remarks),
            }, {
              backend_id: item.dig(:id),
              locale: "ar",
              notes: item.dig(:remarks_un) || item.dig(:remarks),
            },],
          }
        end

        order_items
      end

      def kudu_platform
        Platforms::Platform.find_or_create_by(backend_id: "kudu_sdm")
      end

      def integration_host
        @integration_host ||= Integrations::IntegrationHost.find_by!(name: "Kudu")
      end
    end
  end
end
