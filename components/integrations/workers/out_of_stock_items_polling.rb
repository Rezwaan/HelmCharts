module Integrations
  module Workers
    class OutOfStockItemsPolling
      include Sidekiq::Worker
      # TODO: Implement parallelism
      # TODO: Implement Circuit Breaker
      # TODO: Implement request limit per host
      # TODO: Implement per service host cron with different cadence
      # TODO: This is one long running job break it into multiple job

      # TODO: Remove the conditional after successfully testing on staging,
      # and apply the sidekiq_options here to all environments
      if Rails.configuration.app_env == "staging"
        sidekiq_options queue: "integration"
      end

      def perform
        IntegrationHost.where(enabled: true).each do |integration_host|
          service = IntegrationService.new.service(integration_host)
          service.sync_out_of_stock_items
        rescue NotImplementedError => _
          # We don't want this error logged to Sentry
        rescue => e
          Raven.capture_exception(e, extra: {
            integration_host: integration_host,
          })
        end
      end
    end
  end
end
