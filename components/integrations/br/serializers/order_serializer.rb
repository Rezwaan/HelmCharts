module Integrations
  module Br
    module Serializers
      class OrderSerializer
        def initialize(order:)
          @order = order
        end

        def serialize
          # TODO serialize order object
        end
      end
    end
  end
end
