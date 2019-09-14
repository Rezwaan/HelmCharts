module Integrations
  class IntegrationCatalogService
    include Common::Helpers::PaginationHelper

    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
      integration_catalogs = IntegrationCatalog.all
      integration_catalogs = integration_catalogs.by_id(criteria[:id]) if criteria[:id].present?
      if criteria[:catalog_name].present?
        integration_catalogs = integration_catalogs.by_catalog_name(criteria[:catalog_name])
      end
      if criteria[:integration_host_name].present?
        integration_catalogs = integration_catalogs.by_integration_host_name(criteria[:integration_host_name])
      end
      integration_catalogs = integration_catalogs.order(sort_by => sort_direction) if sort_by

      paginated_dtos(collection: integration_catalogs, page: page, per_page: per_page) do |integration_catalog|
        create_dto(integration_catalog)
      end
    end

    def update(integration_catalog_id:, attributes:)
      integration_catalog = IntegrationCatalog.find_by(id: integration_catalog_id)

      return integration_catalog.errors if integration_catalog.update(attributes)

      create_dto(integration_catalog)
    end

    def fetch(id)
      integration_catalog = IntegrationCatalog.where(id: id).first
      return nil unless integration_catalog

      create_dto(integration_catalog)
    end

    private

    def create_dto(integration_catalog)
      IntegrationCatalogDTO.new(
        {
          id: integration_catalog.id,
          integration_host: integration_catalog.integration_host,
          catalog: integration_catalog.catalog,
          external_reference: integration_catalog.external_reference,
          external_data: integration_catalog.external_data,
          created_at: integration_catalog.created_at,
          updated_at: integration_catalog.updated_at,
        }
      )
    end
  end
end
