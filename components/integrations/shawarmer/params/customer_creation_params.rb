module Integrations
  module Shawarmer
    module Params
      class CustomerCreationParams
        attr_reader :order

        def initialize(order:)
          @order = order
        end

        def build
          # Note: Shawarmer's API is just a wrapper over SDM
          # Max length for names is 50 on SDM, and our customers might not have
          # names but SDM requires them, so we'll make one up in this case.
          name = if order.customer.name
            order.customer.name[0...50]
          else
            "No face"
          end

          name = name.split(" ")

          {
            id: order.customer_id,
            firstName: name.first,
            lastName: name.last,
            gender: 0,
            age: 0,
            mobile: format_mobile(order.customer.phone_number),
            email: "care@posdome.com",
            customerAddresses: [
              {
                id: order.customer_address_id,
                districtName: "",
                addR_DESC: "",
                coordinate: {
                  latitude: order.customer_address.latitude,
                  longitude: order.customer_address.longitude,
                },
              },
            ],
          }
        end

        def format_mobile(mobile)
          "0#{mobile[4, 9]}"
        end
      end
    end
  end
end
