module Integrations
  module Br
    module Params
      class OrderCreationParams
        attr_reader :order, :integration_catalog, :integration_store

        def initialize(order:, integration_catalog:, integration_store:)
          @order = order
          @integration_store = integration_store
          @integration_catalog = integration_catalog
        end

        def build
          Nokogiri::XML::Builder.new do |xml|
            xml.Envelope('xmlns:soap': "http://schemas.xmlsoap.org/soap/envelope/", 'xmlns:xsd': "http://www.w3.org/2001/XMLSchema") do
              xml.parent.namespace = xml.parent.namespace_definitions.first

              xml["soap"].Body do
                xml.HDUE_REGISTERORDER do
                  xml.p_ordercode prefixed_order_id
                  xml.p_orderdate order_date
                  xml.p_storecode integration_store.external_reference
                  xml.p_custcode order.customer_id
                  xml.p_custname order.customer.name
                  # TODO Driver number
                  xml.p_mobile ""
                  xml.p_email "care@posdome.com"
                  xml.p_blocation integration_store.external_data["GPS"]
                  xml.p_grid location
                  xml.p_remarks ""
                  xml.p_tvalue order.amount
                  xml.p_ttax 0.0
                  xml.p_tdiscount order.discount
                  xml.p_deli_charge 0
                  xml.p_otype order.payment_type == "cash" ? "C" : "CR"
                  xml.p_status "S"
                  xml.p_gender ""
                  xml.p_mstatus ""
                  xml.p_deli_type "D"
                  xml.p_addtype ""
                  xml.p_scity ""
                  xml.p_sbuilding ""
                  xml.p_lmark1 ""
                  xml.p_lmark2 ""
                  xml.p_sprovince ""
                  xml.p_sstreet ""
                  xml.p_sarea ""
                  xml.p_custaddress order.customer_address_id
                  # Map order line items
                  order.line_items.each_with_index do |line_item, index|
                    item_detail = line_item.item_detail_reference.with_indifferent_access
                    # Map item detail bundles
                    item_detail[:item_bundles].map do |bundle|
                      order_detail_code = "#{prefixed_order_id}-#{bundle[:item][:item_id]}#{index + 1}"

                      xml.p_orderdetailcode order_detail_code
                      xml.p_productcode bundle[:item][:item_id]
                      xml.p_rate line_item.total_price.to_f / line_item.quantity.to_i
                      xml.p_qty line_item.quantity.to_i
                      xml.p_discount line_item.discount.to_f
                      xml.p_tax 0.0
                      # Map modifiers
                      bundle[:item][:customization_options].each_with_index do |option, index|
                        is_topping = topping?(option[:customization_option_id])
                        total_items = option[:customization_option_item_ids].length
                        percentage = calculate_percentage(total_items)

                        # Map modifier items
                        option[:customization_option_item_ids].each do |item|
                          item = item.split("-").last
                          name = get_item_name(option[:customization_option_id], item)
                          code = "#{bundle[:item][:item_id]}-#{item}"
                          description = "#{bundle[:item][:item_id]}-#{name}"

                          # Toppings
                          xml.p_producttcode is_topping ? "#{bundle[:item][:item_id]}-#{item}" : ""
                          xml.p_toppingcode is_topping ? code : ""
                          xml.p_tpercentage is_topping ? "#{bundle[:item][:item_id]}-#{percentage}" : ""
                          xml.p_toppingdesc is_topping ? description : ""
                          xml.p_tconscode is_topping ? "#{bundle[:item][:item_id]}-#{index + 1}" : ""
                          xml.p_orderdetailtcode is_topping ? order_detail_code : ""

                          # Flavours
                          xml.p_flavourcode !is_topping ? code : ""
                          xml.p_flavourdesc !is_topping ? description : ""
                          xml.p_percentage !is_topping ? "#{bundle[:item][:item_id]}-#{percentage}" : ""
                          xml.p_orderdetailfcode !is_topping ? order_detail_code : ""
                          xml.p_productfcode !is_topping ? "#{bundle[:item][:item_id]}-#{item}" : ""
                          xml.p_conscode !is_topping ? "#{bundle[:item][:item_id]}-#{index + 1}" : ""
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        private

        def order_date
          order.created_at.in_time_zone("Asia/Riyadh")
            .strftime("%Y-%m-%d %H:%M:%S")
        end

        def location
          "#{order.customer_address.latitude},#{order.customer_address.longitude}"
        end

        def topping?(id)
          id.split("-").first == "Toppings"
        end

        def prefixed_order_id
          order.backend_id.to_s
        end

        def get_item_name(id, item)
          name, category_id, product_id = id.split("-")

          singular_name = name.downcase.singularize

          products = integration_catalog.external_data.dig(category_id, name.downcase) || []
          option = products.find { |option|
            option["#{singular_name}_code"] == item
          }

          option&.dig("#{singular_name}_description") || ""
        end

        def calculate_percentage(total_items)
          return 0 if total_items == 0

          (1 / total_items.to_f * 100).to_i
        end
      end
    end
  end
end
