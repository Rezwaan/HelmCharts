module Integrations
  module Romansiah
    module Params
      class OrderCreationParams
        attr_reader :order, :integration_store, :customer, :address_id

        def initialize(order:, integration_store:, customer:, address_id:)
          @order = order
          @integration_store = integration_store
          @customer = customer
          @address_id = address_id
        end

        def build
          {
            foregin_order_id: order.backend_id,
            OrderSource: 50,
            isPaid: order.payment_type == "prepaid",
            customer_id: customer["id"],
            address_id: address_id,
            pick_up_in_store: true,
            pick_up_at_branch_id: integration_store.external_reference.to_i,
            callback_url: "",
            payment_method: "Payments.CashOnDelivery",
            coupon: "",
            dish_type: 10,
            ToDeviceToken: "",
            customer_checkout_note: order.customer_notes || "",
            delivery_date: "",
            language_Id: 1,
            items: build_products,
          }
        end

        private

        def build_products
          products = []
          order.line_items.each do |line_item|
            item_detail = line_item.item_detail.with_indifferent_access
            item_detail[:item_bundles].each do |bundle|
              if bundle[:item][:customization_options].empty?
                products << {
                  product_id: item_detail[:product_id],
                  quantity: line_item.quantity.to_i,
                  attributesXml: "",
                }
                next
              end
              bundle[:item][:customization_options].each do |option|
                option[:customization_option_item_ids].each do |item_id|
                  products << {
                    product_id: item_detail[:product_id],
                    quantity: line_item.quantity.to_i,
                    attributesXml: build_plain_attribute_xml(option, item_id),
                  }
                end
              end
            end
          end

          products
        end

        def build_plain_attribute_xml(option, item_id)
          "<Attributes>" \
            "<ProductAttribute ID='#{option[:customization_option_id]}'>" \
              "<ProductAttributeValue><Value>#{item_id.to_i}</Value></ProductAttributeValue>" \
            "</ProductAttribute>" \
          "</Attributes>"
        end
      end
    end
  end
end
