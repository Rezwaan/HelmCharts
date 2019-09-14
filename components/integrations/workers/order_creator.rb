module Integrations
  module Workers
    class OrderCreator
      include Sidekiq::Worker

      # Max retry count for retries not handled by Sidekiq's built-in retries
      # functionality. e.g. when you capture an exception and do a perform_in
      # this will not increment Sidekiq's retry count, so we maintain an
      # internal one
      MAX_MANUAL_RETRY_COUNT = 5.freeze

      # TODO: Remove the conditional after successfully testing on staging,
      # and apply the sidekiq_options here to all environments
      if Rails.configuration.app_env == "staging"
        sidekiq_options queue: "integration"
      end


      def perform(order_id, current_retry_count = 0)
        order = Orders::OrderService.new.fetch(id: order_id)
        return unless order&.state == :processing

        integration_order = IntegrationOrder.where(order_id: order.id).first
        return if integration_order

        integration_store = IntegrationStore.where(store_id: order.store_id).first
        integration_host = integration_store.integration_host
        service = Integrations::IntegrationService.new.service(integration_host)

        begin
          service.create_order(order: order)

        # Store is unavailable (e.g prayer times)
        rescue Base::Errors::TemporaryUnavailableError => _
          OrderCreator.perform_in(1.minute, order_id)

        # Connection timeouts and resets
        rescue Base::Errors::ConnectionError => e
          if current_retry_count < MAX_MANUAL_RETRY_COUNT
            OrderCreator.perform_in(30.seconds, order_id, current_retry_count + 1)
          else
            Raven.capture_exception(e)
          end
        end
      end
    end
  end
end
