module Integrations
  module Shawarmer
    module Params
      class OrderStatusParams
        attr_reader :integration_order

        def initialize(integration_order:)
          @integration_order = integration_order
        end

        def build
          {
            orderId: integration_order.external_reference,
          }
        end
      end
    end
  end
end
