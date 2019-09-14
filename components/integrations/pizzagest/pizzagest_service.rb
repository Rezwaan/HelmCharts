module Integrations
  module Pizzagest
    class PizzagestService < Base::ServiceInterface
      attr_reader :client
      def initialize(integration_host)
        super(integration_host)
        config = {
          base_url: integration_host.config["base_url"],
          client_code: integration_host.config["client_code"],
          secret: integration_host.config["secret"],
        }
        @client = Integrations::Pizzagest::Client.new(config: config)
      end

      def sync_stores
        stores = @client.get_branches_info
        integration_stores = stores.map { |store|
          {
            external_reference: store["BranchCode"],
            external_data: store,
          }
        }
        persist_stores(integration_stores)
        true
      end

      def sync_catalog_list
        # Maestro doesn't have the concept of catalog but they do have a separate catalog per store
        stores = @client.get_branches_info
        integration_catalogs = stores.map { |store|
          {
            external_reference: store["BranchCode"],
          }
        }
        persist_catalog_list(integration_catalogs)
        true
      end

      def sync_catalog(integration_catalog:)
        catalog_en = @client.get_menu_info(branch_code: integration_catalog[:external_reference], language: "en")
        catalog_ar = @client.get_menu_info(branch_code: integration_catalog[:external_reference], language: "ar")
        integration_catalog.external_data = {catalog_en: catalog_en, catalog_ar: catalog_ar}
        integration_catalog.save

        if integration_catalog.catalog
          catalog = Integrations::Pizzagest::FirestoreCatalogSerializer.new(catalog_en: catalog_en, catalog_ar: catalog_ar).menu
          synced_catalog = Integrations::ImageSyncer.new(firestore_catalog: catalog).sync
          overridden_catalog = Integrations::IntegrationCatalogOverrideService.apply_overrides(
            integration_catalog_id: integration_catalog.id,
            catalog: synced_catalog
          )
          mapped_catalog = IdNumberifier.new.firestore_catalog(overridden_catalog)
          persist_catalog_on_firstore(integration_catalog: integration_catalog, serialized_catalog: mapped_catalog)
        end

        true
      end

      def create_order(order:)
        integration_store = IntegrationStore.where(store_id: order[:store_id], integration_host_id: @integration_host.id).first
        order = IdNumberifier.new.order(order)
        data = OrderSerializer.new(order_dto: order, integration_store: integration_store).serialize
        begin
          external_data = @client.add_new_ticket(order: data)
          integration_order = {
            order_id: order[:id],
            external_reference: external_data["OrderCode"],
            external_data: external_data,
          }
        rescue Base::Errors::ApiError => e
          Raven.capture_exception(e, extra: {order: order, data: data})
          return reject_order(order)
        end
        persist_order(integration_order)
      end

      def sync_order_status(integration_order:)
        order_statuses = @client.get_order_status(phone_number: integration_order.phone_number)

        order_status = order_statuses.find { |order|
          order["TicketCode"] == integration_order.external_reference
        }
        if order_status
          status = order_status["OrderState"]
          mapped_status = OrderStatus.mapped_status(status)
          update_order_status(integration_order, status, mapped_status, order_status)
        end
      end

      def sync_out_of_stock_items
        IntegrationStore.where(integration_host_id: @integration_host.id).where.not(store_id: nil).each do |integration_store|
          out_of_stock_products = @client.get_products_out_of_stock(branch_code: integration_store.external_reference)
          out_of_stock_toppings = @client.get_toppings_out_of_stock(branch_code: integration_store.external_reference)
          out_of_stock_items = []
          out_of_stock_items += out_of_stock_products.map { |out_of_stock_product|
            IdNumberifier.new.id_of(out_of_stock_product["ProductCode"])
          }
          out_of_stock_items += out_of_stock_toppings.map { |out_of_stock_topping|
            IdNumberifier.new.id_of(out_of_stock_topping["ToppingCode"])
          }
          StoreItemAvailabilities::StoreItemAvailabilityService.new.mark_out_of_stock(store_id: integration_store.store_id, item_ids: out_of_stock_items)
        rescue Base::Errors::ApiError, Base::Errors::ConnectionError => e
          Raven.capture_exception(e, extra: {
            out_of_stock_products: out_of_stock_products,
            out_of_stock_toppings: out_of_stock_toppings,
            store_id: integration_store.store_id,
            item_ids: out_of_stock_items,
          })
        end
      end

      def sync_store_statuses
        pizzagest_stores = @client.get_branches_info
        ready_stores_external_references = []
        busy_stores_external_references = []

        # Fill up arrays with external references (branch codes)
        pizzagest_stores&.each do |store|
          external_reference = store["BranchCode"]

          if store["BranchStatusPickup"] == "OA"
            ready_stores_external_references << external_reference
          else
            busy_stores_external_references << external_reference
          end
        end

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

      def sync_working_hours
        day_index = Date.today.wday
        day_str = Date::DAYNAMES[day_index]
        @integration_host.integration_stores.where.not(store_id: nil).each do |integration_store|
          open_time = integration_store.external_data.dig("BranchTimeTable", day_str, "Opening1")
          close_time = integration_store.external_data.dig("BranchTimeTable", day_str, "Closing2")
          next unless open_time || close_time

          n = open_time.size
          open_time = open_time[0..n - 4]
          close_time = close_time[0..n - 4]

          WorkingTimes::WorkingTimeRuleService.new.upsert(
            related_to_type: Stores::Store.name,
            related_to_id: integration_store.store_id,
            week_working_times: [build_working_hours_per_day(open_time, close_time, day_index)],
          )
        end

        true
      end
    end
  end
end
