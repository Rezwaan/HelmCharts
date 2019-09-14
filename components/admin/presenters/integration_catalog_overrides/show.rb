class Admin::Presenters::IntegrationCatalogOverrides::Show
  def initialize(override)
    @override = override
  end

  def present
    {
      id: @override.id,
      integration_catalog_id: @override.integration_catalog_id,
      item_type: @override.item_type,
      item_id: @override.item_id,
      properties: @override.properties,
      created_at: @override.created_at,
      updated_at: @override.updated_at,
    }
  end
end
