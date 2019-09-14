module Integrations
  module Shawarmer
    module Params
      class OrderCreationParams
        attr_reader :order, :integration_store, :payment_types, :customer

        def initialize(order:, integration_store:, payment_types:, customer:)
          @order = order
          @integration_store = integration_store
          @payment_types = payment_types
          @customer = customer.with_indifferent_access
        end

        def build
          {
            PaymentMethod: payment_type&.dig("Id"),
            orderNotes1: order.customer_notes || "",
            orderNotes2: "",
            CancelationTimeInMinutes: 0,
            driverID: 0,
            isTakeOutOrder: true,
            customerID: customer[:Id],
            storeID: integration_store.external_reference,
            customerAddressID: customer[:CustomerAddresses][0][:Id],
            SystemUserOrderID: order.backend_id,
            Items: build_items.flatten,
          }
        end

        private

        def build_items
          order.line_items.map do |line_item|
            item_detail = line_item.item_detail_reference.with_indifferent_access

            item_detail[:item_bundles].map do |bundle|
              {
                ItemId: bundle[:item][:item_id],
                Quantity: line_item.quantity.to_i,
                Modifiers: build_modifiers(bundle[:item][:customization_options]),
              }
            end
          end
        end

        def build_modifiers(options)
          options.map do |option|
            {
              Modifierid: option[:customization_option_id],
              ModifierItems: option[:customization_option_item_ids].map do |customization_option_item_id|
                {
                  ItemId: customization_option_item_id.split("/").last,
                }
              end,
            }
          end
        end

        def payment_type
          shawarmer_payment_metthod = case order.payment_type
          when "cash"
            "CASH"
          when "prepaid"
            "CREDIT CARD"
          end

          payment_types.find do |type|
            type["Name"] == shawarmer_payment_metthod
          end
        end

        def map_modifiers(line_item)
          line_item.order_line_item_modifiers.each_with_object({item_ids: []}) do |modifier, hash|
            hash[get_modifier_id(line_item, modifier.item_reference)][:item_ids] << modifier.item_reference
          end
        end

        def get_modifier_id(line_item, modifier_id)
          integration_catalog.external_data.categories.each do |category|
            category["Items"].each do |item|
              next unless item["ItemId"] == line_item.item_reference

              item["Modifiers"].each do |modifier|
                modifier = modifier["ModifierItems"].find { |modifier_item|
                  modifier_item["ItemId"] == modifier_id
                }

                return modifier["Modifierid"] if modifier
              end
            end
          end
        end
      end
    end
  end
end
