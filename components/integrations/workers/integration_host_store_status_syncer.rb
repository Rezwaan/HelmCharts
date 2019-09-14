module Integrations
  module Workers
    class IntegrationHostStoreStatusSyncer
      include Sidekiq::Worker

      # TODO: Once #80 is merged and tested in production, add this to
      # integrations queue.
      # Retry 0 means it will go to dead upon first failure, we want this
      # because it's StoreStatusPolling's responsibility to take care of this
      # job's lifecycle.
      # See: https://github.com/mperham/sidekiq/wiki/Job-Lifecycle
      sidekiq_options retry: 0 # , queue: "integration"

      # TODO: Implement parallelism
      # TODO: Implement Circuit Breaker
      # TODO: Implement request limit per host
      # TODO: This is one long running job per integration host, break it into multiple job to have a better reliablity

      def perform(integration_host_id)
        integration_host = IntegrationHost.find(integration_host_id)
        service = IntegrationService.new.service(integration_host)

        service.sync_store_statuses
      rescue NotImplementedError => _
        # We don't want this error logged to Sentry
      rescue => e
        Raven.capture_exception(e, extra: {
          integration_host_id: integration_host_id,
        })
      end
    end
  end
end
