module Integrations
  module Shawarmer
    class ShawarmerService < Base::ServiceInterface
      attr_reader :client

      def initialize(integration_host)
        super(integration_host)
        config = {
          base_url: integration_host.config["base_url"],
          username: integration_host.config["username"],
          password: integration_host.config["password"],
        }
        @client = Integrations::Shawarmer::Client.new(config: config)
      end

      def sync_stores
        integration_stores = client.fetch_store_list({
          IncludeClosedStores: "True",
        })

        integration_stores = integration_stores&.map { |store|
          {
            external_reference: store["Id"],
            external_data: store,
          }
        }

        persist_stores(integration_stores)
        true
      end

      def sync_store_statuses
        shawarmer_stores = client.fetch_store_list({
          IncludeClosedStores: "True",
        })

        ready_stores_external_references = []
        busy_stores_external_references = []

        shawarmer_stores.each do |store|
          store_id = store["Id"]

          # It is actually written as CLosedNow in Shawarmer's API
          if store["CLosedNow"]
            busy_stores_external_references << store_id
          else
            ready_stores_external_references << store_id
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

      def sync_catalog_list
        catalog = client.fetch_menu

        integration_catalogs = [{
          external_reference: catalog["Id"],
        }]

        persist_catalog_list(integration_catalogs)
        true
      end

      def sync_catalog(integration_catalog:)
        catalog = client.fetch_menu
        integration_catalog.external_data = catalog
        integration_catalog.save

        if integration_catalog.catalog
          catalog = Serializers::FirestoreCatalogSerializer.new(catalog: catalog).menu
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
        begin
          order_params = build_order_params(order: order)
          validate_order(order_params)
          external_data = submit_order(order_params)

          integration_order = {
            order_id: order.id,
            external_reference: external_data["OrderId"],
            external_data: external_data,
          }
        rescue Base::Errors::ApiError
          return reject_order(order)
        end
        persist_order(integration_order)
      end

      def sync_order_status(integration_order:)
        data = Params::OrderStatusParams.new(
          integration_order: integration_order
        ).build

        order_status = client.fetch_order_status(data)

        if order_status
          order_status = Serializers::OrderStatusSerializer.new(order_status: order_status).serialize
          status = order_status[:status]
          mapped_status = OrderStatus.mapped_status(status)
          update_order_status(integration_order, status, mapped_status, order_status)
        end
      end

      def sync_out_of_stock_items
        @integration_host.integration_stores.where.not(store_id: nil).each do |integration_store|
          items = client.fetch_out_of_stock_items(integration_store.external_reference)
          mark_items_out_of_stock(
            store_id: integration_store.store_id,
            item_ids: items.map { |item| item["ItemId"] }
          )
        end
      rescue Base::Errors::ApiError, Base::Errors::ConnectionError => e
        Raven.capture_exception(e, extra: {
          integration_host: @integration_host,
        })
      end

      def sync_working_hours
        @integration_host.integration_stores.where.not(store_id: nil).each do |integration_store|
          open_time = integration_store.external_data.dig("OpenTimestr")
          close_time = integration_store.external_data.dig("CloseTimestr")
          next unless open_time || close_time

          WorkingTimes::WorkingTimeRuleService.new.upsert(
            related_to_type: Stores::Store.name,
            related_to_id: integration_store.store_id,
            week_working_times: build_working_hours_per_week(open_time, close_time),
          )
        end

        true
      end

      private

      def find_or_create_customer(order:)
        mobile = "0#{order.customer.phone_number[4, 9]}"
        customer = client.fetch_customer_by_phone(mobile)
        return customer if customer

        customer_data = Params::CustomerCreationParams.new(order: order).build
        client.create_customer(customer_data)
      end

      def validate_order(data)
        client.validate_order(data)
      end

      def submit_order(data)
        client.place_order(data)
      end

      def build_order_params(order:)
        integration_store = @integration_host.integration_stores
          .where(store_id: order.store_id).first

        payment_types = client.payment_types
        customer = find_or_create_customer(order: order)
        mapped_order = IdNumberifier.new.order(order)
        Params::OrderCreationParams.new(
          order: mapped_order,
          integration_store: integration_store,
          customer: customer,
          payment_types: payment_types
        ).build
      end

      def mark_items_out_of_stock(store_id:, item_ids:)
        StoreItemAvailabilities::StoreItemAvailabilityService.new.mark_out_of_stock(
          store_id: store_id,
          item_ids: item_ids
        )
      end
    end
  end
end
