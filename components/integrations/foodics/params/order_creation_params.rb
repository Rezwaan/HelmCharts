module Integrations
  module Foodics
    module Params
      class OrderCreationParams
        attr_reader :order, :integration_store, :catalog

        def initialize(order:, integration_store:, catalog:)
          @order = order
          @integration_store = integration_store
          @catalog = catalog
        end

        def build
          {
            branch_hid: integration_store.external_reference,
            final_price: order.amount,
            type: 4, # Delivery
            delivery_price: 0,
            discount_amount: order.discount,
            discount_hid: nil,
            total_tax: 0,
            customer: build_customer,
            products: build_products,
            taxes: [],
            tags: [],
          }
        end

        private

        def build_customer
          {
            name: order.customer.name,
            email: "care@posdome.com",
            phone: order.customer.phone_number[4, 100],
            country_code: "SA",
          }
        end

        def build_products
          products = []
          order.line_items.each do |line_item|
            item_detail = line_item.item_detail_reference.with_indifferent_access

            products += item_detail[:item_bundles].map { |bundle|
              original_price = get_original_price_of_product(item_detail[:product_id], bundle[:item_bundle_id])
              {
                product_hid: item_detail[:product_id],
                product_size_hid: bundle[:item_bundle_id],
                quantity: line_item.quantity.to_i,
                final_price: line_item.total_price.to_f,
                original_price: original_price,
                discount_hid: nil,
                discount_amount: line_item.discount,
                options: build_modifiers(bundle[:item][:customization_options], line_item.quantity.to_i),
              }
            }
          end
          products
        end

        def build_modifiers(customization_options, product_quantity)
          list = []
          customization_options.each do |customization_option|
            prices = get_price_of_options(
              customization_option[:customization_option_id],
              customization_option[:customization_option_item_ids]
            )

            customization_option[:customization_option_item_ids].each_with_index do |customization_option_item_id, index|
              list << {
                hid: customization_option_item_id,
                quantity: 1,
                original_price: prices[index],
                final_price: product_quantity * prices[index],
              }
            end
          end

          list
        end

        def get_price_of_options(customization_option_id, option_ids)
          list = []

          catalog.external_data["modifiers"][customization_option_id]["options"].each do |option|
            next unless option_ids.include? option["hid"]

            list << option["price"]
          end

          list
        end

        def get_original_price_of_product(product_id, size_id)
          catalog.external_data["categories"].each do |key, category|
            product = category["products"].select { |product| product["hid"] == product_id }.first
            next if product.nil?

            size = product["sizes"].select { |size| size["hid"] == size_id }.first
            return size["price"]
          end
        end
      end
    end
  end
end
