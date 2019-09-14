module Integrations
  class IntegrationService
    def initialize
    end

    def create_order(order:)
      integration_store = IntegrationStore.where(store_id: order.store_id).first
      if integration_store&.enabled && integration_store.integration_host.enabled?
        unless order.transmission_medium == "integration"
          order = Orders::OrderService.new.update_transmission(order_id: order.id, transmission: "integration")
        end
        Workers::OrderCreator.perform_async(order.id) if order
      end
    end

    def service(integration_host)
      type = integration_host.integration_type
      "integrations/#{type}/#{type}_service".classify.constantize.new(integration_host)
    end
  end
end
