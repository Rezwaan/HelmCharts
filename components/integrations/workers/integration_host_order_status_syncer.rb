module Integrations
  module Workers
    class IntegrationHostOrderStatusSyncer
      include Sidekiq::Worker

      # Retry 0 means it will go to dead upon first failure, we want this
      # because it's OrderStatusPolling's responsibility to take care of this
      # job's lifecycle.
      # See: https://github.com/mperham/sidekiq/wiki/Job-Lifecycle
      sidekiq_options  retry: 0

      # TODO: Remove the conditional after successfully testing on staging,
      # and apply the sidekiq_options here to all environments
      if Rails.configuration.app_env == "staging"
        sidekiq_options queue: "integration"
      end

      # TODO: Implement parallelism
      # TODO: Implement Circuit Breaker
      # TODO: Implement request limit per host
      # TODO: This is one long running job per integration host, break it into multiple job to have a better reliablity

      # Kill jobs if they stay too long
      # Make a separate queue for integrations
      # Launch separate jobs per integration host

      def perform(integration_host_id)
        IntegrationOrder.where(status: "pending", integration_host_id: integration_host_id)
          .order(last_synced_at: :asc).each do |integration_order|
          if integration_order.created_at < 4.hours.ago # @TODO: Move expiry time to host config
            integration_order.update(status: :expired)
            next
          end

          service = IntegrationService.new.service(integration_order.integration_host)
          service.sync_order_status(integration_order: integration_order)

        rescue => e
          # We are rescuing to make sure that an error in one order is not blocking order status updating for all
          Raven.capture_exception(e, extra: {
            integration_order: integration_order,
            integration_host_id: integration_host_id,
          })
        ensure
          integration_order.update(last_synced_at: Time.now)
        end
        # TODO: Implement bulk order status
      end
    end
  end
end
