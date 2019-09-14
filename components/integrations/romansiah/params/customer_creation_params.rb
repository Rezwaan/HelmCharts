module Integrations
  module Romansiah
    module Params
      class CustomerCreationParams
        attr_reader :order, :password

        def initialize(order:, password:)
          @order = order
          @password = password
        end

        def build
          {
            id: order.customer_id,
            first_name: order.customer.name.split(" ")[0],
            phone: format_mobile(order.customer.phone_number),
            password: password,
          }
        end

        def format_mobile(mobile)
          "0#{mobile[4, 9]}"
        end
      end
    end
  end
end
