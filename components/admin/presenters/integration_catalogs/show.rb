class Admin::Presenters::IntegrationCatalogs::Show
  def initialize(integration_catalog)
    @integration_catalog = integration_catalog
  end

  def present
    {
      id: @integration_catalog.id,
      catalog: @integration_catalog.catalog,
      integration_host: @integration_catalog.integration_host,
      external_reference: @integration_catalog.external_reference,
      external_data: @integration_catalog.external_data,
      created_at: @integration_catalog.created_at,
      updated_at: @integration_catalog.updated_at,
    }
  end
end
