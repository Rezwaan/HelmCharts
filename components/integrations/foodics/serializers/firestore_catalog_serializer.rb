module Integrations
  module Foodics
    module Serializers
      class FirestoreCatalogSerializer
        attr_reader :catalog, :mapped_menu

        # @param [Hash] catalog The Foodics catalog which will be serialized to a Dome catalog
        # @param [BigDecimal] tax_rate The tax rate for the Foodics business this catalog is tied to
        def initialize(catalog:, tax_rate:)
          @catalog = catalog.with_indifferent_access
          @tax_rate = tax_rate

          @mapped_menu = {
            name: "Menu-#{SecureRandom.uuid}",
            sets: {},
            items: {},
            bundles: {},
            products: {},
            item_sets: {},
            categories: {},
            bundle_sets: {},
            item_bundles: {},
            customization_options: {},
            customization_ingredients: {},
            customization_option_items: {},
            customization_ingredient_items: {},
          }
        end

        def menu
          catalog[:categories].each_with_index do |(key, category), index|
            serialize_category(category, index)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_products(category)
          category[:products].each_with_index do |product, index|
            product_id = product[:hid]
            mapped_menu[:products][product_id] = {
              id: product_id,
              name: item_name(product, :en),
              name_ar: item_name(product, :ar),
              reference_name: product_id,
              images: product[:image_path].blank? ? {} : {"#{SecureRandom.uuid}": product[:image_path]},
              weight: product[:index],
              bundle_ids: {"#{product_id}": product_id},
              description: item_description(product, :en),
              description_ar: item_description(product, :ar),
            }

            mapped_menu[:bundles][product_id] = {
              id: product_id,
              name: item_name(product, :en),
              name_ar: item_name(product, :ar),
              reference_name: product_id,
              images: product[:image_path].blank? ? {} : {"#{SecureRandom.uuid}": product[:image_path]},
              weight: product[:index],
              description: item_description(product, :en),
              description_ar: item_description(product, :ar),
              item_bundle_ids: {"#{product_id}": product_id},
            }

            mapped_menu[:items][product_id] = {
              id: product_id,
              reference_name: product_id,
              images: product[:image_path].blank? ? {} : {"#{SecureRandom.uuid}": product[:image_path]},
              customization_option_ids: serialize_customization_options(product, category),
              customization_ingredient_ids: {},
            }

            product[:sizes].each do |size|
              size_id = size[:hid]

              price = if product[:taxable]
                BigDecimal(size[:price]) + (BigDecimal(size[:price]) * @tax_rate)
              else
                size[:price]
              end

              mapped_menu[:item_bundles][size_id] = {
                id: size_id,
                name: item_name(size, :en),
                name_ar: item_name(size, :ar),
                description: item_description(size, :en),
                description_ar: item_description(size, :ar),
                price: price.to_s,
                weight: size[:index],
                item_id: product_id,
                bundle_id: product_id,
              }
            end
          end
        end

        def serialize_customization_options(product, category)
          customization_options_ids = {}
          product[:modifiers].each_with_index do |modifier, index|
            id = modifier[:hid]
            modifier_data = catalog[:modifiers][id]
            mapped_menu[:customization_options][id] = {
              id: id,
              name: item_name(modifier_data, :en),
              name_ar: item_name(modifier_data, :ar),
              reference_name: id,
              images: {},
              max_selection: modifier[:relationship_data][:maximum_options].to_i,
              min_selection: modifier[:relationship_data][:minimum_options].to_i,
              customization_option_item_ids: serialize_customization_option_items(modifier, category),
            }

            customization_options_ids[id] = {
              id: id,
              weight: index,
            }
          end

          customization_options_ids
        end

        def serialize_customization_option_items(modifier, category)
          same_limits = modifier[:relationship_data][:minimum_options].to_i == 1 &&
            modifier[:relationship_data][:maximum_options].to_i == 1
          modifier_id = modifier[:hid]
          option_items = {}
          modifier_data = catalog[:modifiers][modifier_id]
          modifier_data[:options].each do |modifier_option|
            next if modifier[:relationship_data][:excluded_options].include?(modifier_option[:hid])

            id = modifier_option[:hid]
            mapped_menu[:customization_option_items][id] = {
              id: id,
              name: item_name(modifier_option, :en),
              name_ar: item_name(modifier_option, :ar),
              price: "0.0",
              weight: modifier_option[:index],
              default_selected: (same_limits && modifier_option[:index] == 0),
              customization_option_id: modifier_id,
              item_id: id,
            }

            add_item({
              id: id,
              reference_name: id,
              images: {},
              customization_option_ids: {},
              customization_ingredient_ids: {},
            })

            option_items[id] = id
          end

          option_items
        end

        def serialize_category(category, weight)
          category_id = category[:hid]
          mapped_menu[:categories][category_id] = {
            id: category_id,
            name: item_name(category, "en"),
            name_ar: item_name(category, "ar"),
            weight: category[:index],
            product_ids: product_ids(category),
          }
        end

        def product_ids(category)
          category[:products].each_with_object({}) do |product, hash|
            product_id = product[:hid]
            hash[product_id] = product_id
          end
        end

        def item_name(item, lang)
          item.dig(:name, lang) || " "
        end

        def item_description(item, lang)
          item.dig(:description, lang) || " "
        end

        def add_item(item)
          @item_ids ||= SortedSet.new
          return if @item_ids.include? item[:id]
          @item_ids.add item[:id]
          mapped_menu[:items][item[:id]] = item
        end
      end
    end
  end
end
