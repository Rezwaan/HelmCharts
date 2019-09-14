module Integrations
  class IntegrationStoreService
    include Common::Helpers::PaginationHelper

    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :created_at, sort_direction: "desc")
      integration_stores = IntegrationStore.all
      integration_stores = integration_stores.by_id(criteria[:id]) if criteria[:id].present?
      integration_stores = integration_stores.by_store_name(criteria[:store_name]) if criteria[:store_name].present?
      integration_stores = integration_stores.by_integration_host_name(criteria[:integration_host_name]) if criteria[:integration_host_name].present?
      integration_stores = integration_stores.order(sort_by => sort_direction) if sort_by

      paginated_dtos(collection: integration_stores, page: page, per_page: per_page) do |integration_store|
        create_dto(integration_store)
      end
    end

    def update(integration_store_id:, attributes:)
      integration_store = IntegrationStore.find_by(id: integration_store_id)

      if integration_store.update(attributes)
        create_dto(integration_store)
      else
        integration_store.errors
      end
    end

    def fetch(id)
      integration_store = IntegrationStore.where(id: id).first
      return nil unless integration_store

      create_dto(integration_store)
    end

    def fetch_by_external_reference(external_reference:, integration_host_id:)
      integration_store = IntegrationStore.find_by(
        external_reference: external_reference,
        integration_host_id: integration_host_id
      )

      return nil unless integration_store

      create_dto(integration_store)
    end

    private

    def create_dto(integration_store)
      IntegrationStoreDTO.new({
        id: integration_store.id,
        store: integration_store.store,
        integration_host: integration_store.integration_host,
        external_reference: integration_store.external_reference,
        external_data: integration_store.external_data,
        enabled: integration_store.enabled,
        created_at: integration_store.created_at,
        updated_at: integration_store.updated_at,
      })
    end
  end
end
