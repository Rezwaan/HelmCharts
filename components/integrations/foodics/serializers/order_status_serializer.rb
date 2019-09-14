module Integrations
  module Foodics
    module Serializers
      class OrderStatusSerializer
        attr_reader :order

        def initialize(order:)
          @order = order.with_indifferent_access
        end

        def serialize
          {
            id: order[:hid],
            guid: order[:guid],
            number: order[:number],
            customer: order[:customer],
            status: order[:status],
          }
        end
      end
    end
  end
end
