module Integrations
  module Shawarmer
    module Serializers
      class OrderStatusSerializer
        attr_reader :order_status

        def initialize(order_status:)
          @order_status = order_status.with_indifferent_access
        end

        def serialize
          {
            id: order_status[:id],
            check_id: order_status[:CheckID],
            order_id: order_status[:OrderId],
            customer_id: order_status[:CustomerOrderID],
            status: order_status[:Entry],
            can_cancel: order_status[:CAN_CANCEL],
          }
        end
      end
    end
  end
end
