module Integrations
  module Workers
    class OrderStatusPolling
      include Sidekiq::Worker

      # Retry 0 means it will go to dead upon first failure. This is desirable
      # because this worker will be launched through a sidekiq-cron every minute
      # and we don't want to flood the integrations with requests.
      # See: https://github.com/mperham/sidekiq/wiki/Job-Lifecycle
      sidekiq_options retry: 0

      # TODO: Remove the conditional after successfully testing on staging,
      # and apply the sidekiq_options here to all environments
      if Rails.configuration.app_env == "staging"
        sidekiq_options queue: "integration"
      end

      def perform
        # Launch an order status syncer per integration host
        Integrations::IntegrationHost.where(enabled: true).each do |host|
          IntegrationHostOrderStatusSyncer.perform_async(host.id)
        end
      end
    end
  end
end
