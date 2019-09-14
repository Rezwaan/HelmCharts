module Integrations
  module Workers
    class StoreStatusPolling
      include Sidekiq::Worker

      # TODO: Once #80 is merged and tested in production, add this to
      # integrations queue.
      # Retry 0 means it will go to dead upon first failure. This is desirable
      # because this worker will be launched through a sidekiq-cron every minute
      # and we don't want to flood the integrations with requests.
      # See: https://github.com/mperham/sidekiq/wiki/Job-Lifecycle
      sidekiq_options retry: 0 # , queue: "integration"

      def perform
        IntegrationHost.where(enabled: true).each do |integration_host|
          IntegrationHostStoreStatusSyncer.perform_async(integration_host.id)
        rescue NotImplementedError => _
          # We don't want this error logged to Sentry
        rescue => e
          Raven.capture_exception(e)
        end
      end
    end
  end
end
