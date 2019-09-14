module Integrations
  module Base
    class ServiceInterface
      def initialize(integration_host, provider = nil)
        @integration_host = integration_host
        @author = Author.by_system(entity: ["integration", provider].compact.join("/"))
      end

      def sync_stores
        raise NotImplementedError.new("Implement me please")
      end

      def sync_catalog_list
        raise NotImplementedError.new("Implement me please")
      end

      def sync_catalog(integration_catalog:)
        raise NotImplementedError.new("Implement me please")
      end

      def create_order(order:)
        raise NotImplementedError.new("Implement me please")
      end

      def sync_order_status(integration_order:)
        raise NotImplementedError.new("Implement me please")
      end

      def sync_out_of_stock_items
        raise NotImplementedError.new("Implement me please")
      end

      def sync_store_statuses
        raise NotImplementedError.new("Implement me please")
      end

      def sync_working_hours
        raise NotImplementedError.new("Implement me please")
      end

      private

      def persist_stores(stores)
        # @TODO Implement scenarios where store get removed from the integration host
        stores.each do |store|
          integration_store = IntegrationStore.where(integration_host_id: @integration_host[:id], external_reference: store[:external_reference]).first_or_initialize
          integration_store.external_data = store[:external_data]
          integration_store.save!
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      def persist_catalog_list(catalogs)
        # @TODO Implement scenarios where store get removed from the integration host
        catalogs.each do |catalog|
          integration_catalog = IntegrationCatalog.where(
            integration_host_id: @integration_host[:id],
            external_reference: catalog[:external_reference]
          ).first_or_initialize

          if catalog[:external_data]
            integration_catalog.external_data = catalog[:external_data]
          end

          integration_catalog.save!
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end

      def persist_catalog_on_firstore(integration_catalog:, serialized_catalog:)
        catalog = integration_catalog.catalog
        collection_name = "dome_lite.catalogs"
        document_path = "#{collection_name}/#{catalog.id}"
        bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
        bot.create_document(path: document_path, data: serialized_catalog)
      end

      def publish_catalog(integration_catalog:, catalog_ar:, catalog_en:)
        version_data = {
          # external_data: integration_catalog.external_data, Find a workaround since Firestore is not allowing documents larger than 1MB
          catalog_en: catalog_en,
          catalog_ar: catalog_ar,
          catalog_id: integration_catalog.catalog_id,
          created_at: Time.now.to_i,
        }

        # TODO: Log the catalogs and external data to a Google Cloud Bucket.

        Catalogs::CatalogService.new.publish_version(catalog_version: version_data, catalog_en: catalog_en, catalog_ar: catalog_ar)
      end

      def persist_order(order)
        integration_order = IntegrationOrder.new(integration_host_id: @integration_host[:id], external_reference: order[:external_reference], status: "pending", last_synced_at: Time.now)
        integration_order.external_data = order[:external_data]
        integration_order.order_id = order[:order_id]
        integration_order.save
      end

      def reject_order(order)
        # TODO add reject_resean as integration failure
        Orders::StatusUpdater.new(order: order, author: @author).rejected_by_store(reject_reason_id: nil)
      end

      def update_order_status(integration_order, status, mapped_status, external_data = {})
        last_integration_stauts = IntegrationOrderStatus.where(integration_order_id: integration_order.id).select(:id, :status, :created_at).order(:created_at).last
        return if last_integration_stauts && last_integration_stauts[:status] == status
        IntegrationOrderStatus.create(status: status, external_data: external_data, integration_order_id: integration_order.id)
        order = integration_order.order
        begin
          case mapped_status
          when :accepted_by_store
            Orders::StatusUpdater.new(order: order, author: @author).accepted_by_store
            integration_order.update(status: :finalized)
          when :out_for_delivery
            Orders::StatusUpdater.new(order: order, author: @author).out_for_delivery
            integration_order.update(status: :finalized)
          when :cancelled_by_store
            Orders::StatusUpdater.new(order: order, author: @author).cancelled_by_store
            integration_order.update(status: :finalized)
          end
        rescue Orders::Error::StatusChangedNotAllowed => _
          # order was updated from somewhere else
          integration_order.update(status: :finalized)
        end
      end

      def publish_store_statuses(store_ids:, status:)
        store_service = Stores::StoreStatusService.new

        case status
        when Stores::StoreStatus.statuses[:ready]
          store_service.batch_set_ready(store_ids: store_ids)
        when Stores::StoreStatus.statuses[:temporary_busy]
          store_service.batch_set_temporary_busy(store_ids: store_ids)
        end
      end

      def build_working_hours_per_week(open_time, close_time)
        (0..6).map do |day|
          build_working_hours_per_day(open_time, close_time, day)
        end
      end

      def build_working_hours_per_day(open_time, close_time, day)
        {
          weekday: day,
          start_from: open_time,
          end_at: close_time,
        }.with_indifferent_access
      end
    end
  end
end
