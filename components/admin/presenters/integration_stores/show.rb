class Admin::Presenters::IntegrationStores::Show
  def initialize(integration_store)
    @integration_store = integration_store
  end

  def present
    {
      id: @integration_store.id,
      store: @integration_store.store,
      integration_host: @integration_store.integration_host,
      external_reference: @integration_store.external_reference,
      external_data: @integration_store.external_data,
      enabled: @integration_store.enabled,
      created_at: @integration_store.created_at,
      updated_at: @integration_store.updated_at,
    }
  end
end
