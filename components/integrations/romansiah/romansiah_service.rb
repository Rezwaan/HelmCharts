module Integrations
  module Romansiah
    class RomansiahService < Base::ServiceInterface
      attr_reader :client

      def initialize(integration_host)
        super(integration_host)
        config = {
          base_url: integration_host.config["base_url"],
          phone: integration_host.config["phone"],
          password: integration_host.config["password"],
        }
        @client = Integrations::Romansiah::Client.new(config: config)
      end

      def sync_stores
        client.branches
        persist_stores(build_integration_stores)
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
        catalog_en = fetch_english_catalog
        catalog_ar = fetch_arabic_catalog
        integration_catalog.external_data = catalog_en
        integration_catalog.save

        if integration_catalog.catalog
          firestore_catalog = Serializers::FirestoreCatalogSerializer.new(catalog_en: catalog_en, catalog_ar: catalog_ar).menu
          synced_catalog = Integrations::ImageSyncer.new(firestore_catalog: firestore_catalog).sync
          overridden_catalog = Integrations::IntegrationCatalogOverrideService.apply_overrides(
            integration_catalog_id: integration_catalog.id,
            catalog: synced_catalog
          )
          persist_catalog_on_firstore(integration_catalog: integration_catalog, serialized_catalog: overridden_catalog)
        end

        true
      end

      def create_order(order:)
        data = build_order_params(order: order)
        client.create_order(data)
        integration_order = {
          order_id: order.id,
          external_reference: client.result["data"],
          external_data: client.result,
        }
        persist_order(integration_order)
      end

      def sync_order_status(integration_order:)
        order_status = client.get_order_status_by_id(integration_order.external_data["data"])
        if order_status
          status = order_status["order_status"]
          mapped_status = OrderStatus.mapped_status(status)
          update_order_status(integration_order, status, mapped_status, order_status)
        end
      end

      private

      def build_integration_stores
        client.result.map do |store|
          {
            external_reference: store["id"],
            external_data: store,
          }
        end
      end

      def fetch_english_catalog
        client.set_lang("1")
        categories = client.get_catalog
        products = get_products(categories)

        Integrations::Romansiah::Adapters::CatalogAdapter.new([categories, products]).adapt
      end

      def fetch_arabic_catalog
        client.set_lang("2")
        categories = client.get_catalog
        products = get_products(categories)

        Integrations::Romansiah::Adapters::CatalogAdapter.new([categories, products]).adapt
      end

      def get_products(categories)
        threads = number_of_threads_for_syncing
        Parallel.map(categories, in_threads: threads) { |category|
          client.get_products({categoryId: category["id"]})
        }.flatten.uniq { |item| item["id"] }
      end

      def number_of_threads_for_syncing
        Rails.application.secrets.integrations[:number_of_threads_for_syncing]
      end

      def build_order_params(order:)
        integration_store = @integration_host.integration_stores
          .where(store_id: order.store_id).first

        customer = client.get_customer_by_phone(@integration_host.config["phone"])

        address_data = Params::AddressCreationParams.new(customer: customer, order: order).build
        address = client.create_address(address_data)

        Params::OrderCreationParams.new(
          order: order,
          integration_store: integration_store,
          customer: customer,
          address_id: address["data"],
        ).build
      end
    end
  end
end
