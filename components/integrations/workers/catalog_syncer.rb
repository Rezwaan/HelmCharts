module Integrations
  module Workers
    class CatalogSyncer
      include Sidekiq::Worker

      # TODO: Remove the conditional after successfully testing on staging,
      # and apply the sidekiq_options here to all environments
      if Rails.configuration.app_env == "staging"
        sidekiq_options queue: "integration"
      end

      def perform(integration_catalog_id)
        integration_catalog = IntegrationCatalog.find(integration_catalog_id)

        return if integration_catalog.nil?

        integration_service = get_integration_service(integration_catalog)
        integration_service.sync_catalog(integration_catalog: integration_catalog)
      end

      private

      def get_integration_service(integration_catalog)
        Integrations::IntegrationService.new.service(integration_catalog.integration_host)
      end
    end
  end
end
