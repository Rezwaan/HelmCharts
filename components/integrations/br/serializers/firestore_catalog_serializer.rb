module Integrations
  module Br
    module Serializers
      class FirestoreCatalogSerializer
        attr_reader :catalog, :mapped_menu

        def initialize(catalog:)
          @catalog = catalog.with_indifferent_access
          @lotus_biscoff_hack = Serializers::Hacks::LotusBiscoff.new
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
          catalog.each_with_index do |(key, category), index|
            serialize_category(category, index)
            serialize_products(category)
          end

          lotus_biscoff = @lotus_biscoff_hack.build_catalog(mapped_menu[:categories].keys.length)

          mapped_menu.keys.each do |key|
            next if key == :name
            mapped_menu[key].merge!(lotus_biscoff[key])
          end

          mapped_menu
        end

        private

        def serialize_category(category, weight)
          category_id = category[:category_code]
          mapped_menu[:categories][category_id] = {
            id: category_id,
            name: category[:category_description],
            name_ar: category[:arabic_category],
            weight: weight,
            product_ids: product_ids(category),
          }
        end

        def serialize_products(category)
          category[:products].each_with_index do |product, index|
            product_id = product[:plu_code]
            desc = product[:product_and_description].blank? ? " " : product[:product_and_description]
            mapped_menu[:products][product_id] = {
              id: product_id,
              name: product[:plu_description],
              name_ar: product[:plu_ar_description],
              reference_name: product_id,
              images: product[:image_path].blank? ? {} : {"#{SecureRandom.uuid}": product[:image_path]},
              weight: index,
              bundle_ids: {"#{product_id}": product_id},
              description: desc,
              description_ar: " ",
            }

            mapped_menu[:bundles][product_id] = {
              id: product_id,
              name: product[:plu_description],
              name_ar: product[:plu_ar_description],
              reference_name: product_id,
              images: product[:image_path].blank? ? {} : {"#{SecureRandom.uuid}": product[:image_path]},
              weight: index,
              description: desc,
              description_ar: " ",
              item_bundle_ids: {"#{product_id}": product_id},
            }

            mapped_menu[:items][product_id] = {
              id: product_id,
              reference_name: product_id,
              images: product[:image_path].blank? ? {} : {"#{SecureRandom.uuid}": product[:image_path]},
              customization_option_ids: serialize_customization_options(product, category),
              customization_ingredient_ids: {},
            }

            mapped_menu[:item_bundles][product_id] = {
              id: product_id,
              name: product[:plu_description],
              name_ar: product[:plu_ar_description],
              description: desc,
              description_ar: " ",
              price: product[:price].to_s,
              weight: index,
              item_id: product_id,
              bundle_id: product_id,
            }
          end
        end

        def serialize_customization_options(product, category)
          customization_options_ids = {}

          # If no_of_flavour or min_flavour are greater than 0 then we build the customization_options
          if product[:no_of_flavour].to_i > 0 || product[:min_flavour].to_i > 0
            falvour_id = "Flavours-#{category[:category_code]}-#{product[:plu_code]}"

            mapped_menu[:customization_options][falvour_id] = {
              id: falvour_id,
              name: "Flavours",
              name_ar: "نكهات",
              reference_name: falvour_id,
              images: {},
              max_selection: product[:no_of_flavour].to_i,
              min_selection: product[:min_flavour].to_i,
              customization_option_item_ids: serialize_falvours(product, category),
            }

            customization_options_ids[falvour_id] = {
              id: falvour_id,
              weight: 0
            }
          end

          # If no_of_topping or min_topping are greater than 0 then we build the customization_options
          if product[:no_of_topping].to_i > 0 || product[:min_topping].to_i > 0
            topping_id = "Toppings-#{category[:category_code]}-#{product[:plu_code]}"

            mapped_menu[:customization_options][topping_id] = {
              id: topping_id,
              name: "Toppings",
              name_ar: "إضافات",
              reference_name: topping_id,
              images: {},
              max_selection: product[:no_of_topping].to_i,
              min_selection: product[:min_topping].to_i,
              customization_option_item_ids: serialize_toppings(product, category),
            }

            customization_options_ids[topping_id] = {
              id: topping_id,
              weight: 1
            }
          end

          customization_options_ids
        end

        def serialize_falvours(product, category)
          result = {}
          same_limits = product[:no_of_flavour].to_i == 1 && product[:min_flavour].to_i == 1
          category[:flavours].each_with_index do |flavour, index|
            id = "#{category[:category_code]}-#{product[:plu_code]}-#{flavour[:flavour_code]}"
            flavour_id = "Flavours-#{category[:category_code]}-#{product[:plu_code]}"
            flavour_code = flavour[:flavour_code]
            mapped_menu[:customization_option_items][id] = {
              id: id,
              name: flavour[:flavour_description],
              name_ar: flavour[:arabic_description],
              price: "0.0",
              weight: index,
              default_selected: (same_limits && index == 0), # TODO
              customization_option_id: flavour_id,
              item_id: flavour_code,
            }

            add_item({
              id: flavour_code,
              reference_name: flavour_code,
              images: {},
              customization_option_ids: {},
              customization_ingredient_ids: {},
            })

            result[id] = id
          end

          result
        end

        def serialize_toppings(product, category)
          result = {}
          same_limits = product[:no_of_topping].to_i == 1 && product[:min_topping].to_i == 1
          category[:toppings].each_with_index do |topping, index|
            id = "#{category[:category_code]}-#{product[:plu_code]}-#{topping[:topping_code]}"
            topping_id = "Toppings-#{category[:category_code]}-#{product[:plu_code]}"
            topping_code = topping[:topping_code]
            mapped_menu[:customization_option_items][id] = {
              id: id,
              name: topping[:topping_description],
              name_ar: topping[:arabic_description],
              price: "0.0",
              weight: index,
              default_selected: (same_limits && index == 0), # TODO
              customization_option_id: topping_id,
              item_id: topping_code,
            }

            add_item({
              id: topping_code,
              reference_name: topping_code,
              images: {},
              customization_option_ids: {},
              customization_ingredient_ids: {},
            })

            result[id] = id
          end

          result
        end

        def product_ids(category)
          category[:products].each_with_object({}) do |product, hash|
            product_id = product[:plu_code]
            hash[product_id] = product_id
          end
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
