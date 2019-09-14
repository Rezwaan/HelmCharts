class Admin::Presenters::IntegrationHosts::Show
  def initialize(integration_host)
    @integration_host = integration_host
  end

  def present
    {
      id: @integration_host.id,
      name: @integration_host.name,
      integration_type: @integration_host.integration_type,
      config: @integration_host.config,
      enabled: @integration_host.enabled,
    }
  end
end
