module Integrations
  module Pizzagest
    class OrderSerializer
      def initialize(order_dto:, integration_store:)
        @order_dto = order_dto
        @integration_store = integration_store
      end

      def serialize
        ticket_lines = @order_dto.line_items.map { |line_item| ticket_line(line_item) }

        res = {
          "TicketLines" => ticket_lines,
          "Email" => "care@posdome.com",
          "BranchCode" => @integration_store[:external_reference],
          "Phone" => phone_number,
          "Language" => "en",
          "StreetNumber" => "",
          "Building" => "",
          "Staircase" => "",
          "Floor" => "",
          "Door" => "",
          "ExtraIndications" => "Swyft Order ID: #{@order_dto.backend_id}",
          "Latitude" => @order_dto.customer_address.latitude,
          "Longitude" => @order_dto.customer_address.longitude,
          "DeliveryDate" => (Time.now + 10.minutes).in_time_zone("Asia/Riyadh").strftime("%Y-%m-%d %H:%M:%S"),
          "PayTypeCode" => payment_type_code,
          "OrderType" => "P",
          "TotalAmount" => ticket_lines.sum(0) { |ticket_line| ticket_line["Price"] },
        }

        res
      end

      private

      def ticket_line(line_item)
        product = JSON.parse(line_item[:item_detail_reference][:product_id])

        modifiers = line_item[:item_detail_reference][:item_bundles].map { |item_bundle|
          item_bundle[:item][:customization_options].map { |customization_option|
            customization_option[:customization_option_item_ids].map { |customization_option_item_id|
              customization_option_item_id.split("/").last
            }
          }
        }.flatten.compact

        modifiers += product["required_topping"]

        modifiers += product["preselected_topping"].reject { |topping| modifiers.include?(topping) }.map { |topping| "-#{topping}" }

        {
          "ProductCode" => product["code"],
          "Quantity" => line_item.quantity.to_i,
          "Topping" => modifiers.map { |topping| "#{topping};" }.join(""),
          "Price" => line_item.total_price.to_f / line_item.quantity.to_i,
        }
      end

      def phone_number
        "0#{@order_dto.customer.phone_number[4, 100]}"
      end

      def payment_type_code
        methods = {
          cash: 1,
          wallet: 26,
          prepaid: 26,
        }

        methods[@order_dto.payment_type.to_sym]
      end
    end
  end
end
