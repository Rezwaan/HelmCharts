module Integrations
  module Br
    class BrService < Base::ServiceInterface
      attr_reader :client
      def initialize(integration_host)
        super(integration_host)
        config = {
          wsdl_url: integration_host.config["wsdl_url"],
        }
        @client = Integrations::Br::Client.new(config: config)
      end

      def sync_stores
        integration_stores = @client.get_stores.xpath("//*[starts-with(local-name(), 'Entry')]").map { |entry|
          external_data = entry.children.each_with_object({}) { |child, store|
            store[child.name] = child.text
          }

          {
            external_reference: external_data["STORECODE"],
            external_data: external_data,
          }
        }

        persist_stores(integration_stores)
        true
      end

      def sync_catalog_list
        integration_catalog = {
          external_reference: nil,
        }

        persist_catalog_list([integration_catalog])
        true
      end

      def sync_catalog(integration_catalog:)
        catalog = Adapters::CatalogAdapter.new(@client.get_catalog).adapt
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
        integration_store = @integration_host.integration_stores
          .where(store_id: order.store_id).first
        integration_catalog = @integration_host.integration_catalogs.last
        mapped_order = IdNumberifier.new.order(order)
        data = Params::OrderCreationParams.new(
          order: mapped_order,
          integration_store: integration_store,
          integration_catalog: integration_catalog
        ).build

        @client.register_order(data: data)

        integration_order = {
          order_id: order.id,
          external_reference: order.backend_id.to_s,
        }

        persist_order(integration_order)
      end

      def sync_order_status(integration_order:)
        data = Params::OrderStatusParams.new(
          integration_order: integration_order
        ).build

        order_status = @client.order_status(data: data)

        if order_status
          order_status = Serializers::OrderStatusSerializer.new(order_status: order_status).serialize
          status = order_status[:status]
          mapped_status = OrderStatus.mapped_status(status)
          update_order_status(integration_order, status, mapped_status, order_status)
        end
      end
    end
  end
end
