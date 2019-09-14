module Integrations
  module Workers
    class SyncWorkingHours
      include Sidekiq::Worker

      # TODO: Remove the conditional after successfully testing on staging,
      # and apply the sidekiq_options here to all environments
      if Rails.configuration.app_env == "staging"
        sidekiq_options queue: "integration"
      end

      def perform
        IntegrationHost.where(enabled: true, integration_type: [1, 4]).each do |integration_host|
          service = IntegrationService.new.service(integration_host)
          service.sync_stores
          service.sync_working_hours
        end
      rescue
      end
    end
  end
end
