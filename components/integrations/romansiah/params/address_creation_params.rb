module Integrations
  module Romansiah
    module Params
      class AddressCreationParams
        attr_reader :order, :customer

        def initialize(customer:, order:)
          @order = order
          @customer = customer
        end

        def build
          {
            address_name: "address-#{customer["phone"]}",
            address_line: "address-#{customer["phone"]}",
            phone: customer["phone"],
            google_latitude: order.customer_address.latitude.to_s,
            google_longitude: order.customer_address.longitude.to_s,
            customer_id: customer["id"],
          }
        end
      end
    end
  end
end
