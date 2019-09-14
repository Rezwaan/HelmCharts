module Integrations
  module Br
    module Serializers
      class CatalogSerializer
        attr_reader :catalog, :lang, :mapped_menu
        def initialize(catalog:, lang:)
          @catalog = catalog
          @lang = lang
          @mapped_menu = {
            sets: [],
            items: [],
            bundles: [],
            products: [],
            item_sets: [],
            categories: [],
            bundle_sets: [],
            item_bundles: [],
            customization_options: [],
            customization_ingredients: [],
            customization_option_items: [],
            customization_ingredient_items: [],
          }
        end

        def menu
          catalog.each_with_index do |(key, category), index|
            serialize_category(category, index)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_category(category, weight)
          mapped_menu[:categories] << {
            id: category[:category_code],
            name: lang == "en" ? category[:category_description] : category[:arabic_category],
            weight: weight,
            product_ids: product_ids(category),
          }
        end

        def serialize_products(category)
          category[:products].each_with_index do |product, index|
            customization_option_ids = []

            mapped_menu[:products] << {
              id: product[:plu_code],
              name: lang == "en" ? product[:plu_description] : product[:plu_ar_description],
              images: [create_image_object(product[:image_path])],
              weight: index,
              bundle_ids: [product[:plu_code]],
              description: product[:product_and_description],
              calories: product[:calories],
            }

            mapped_menu[:bundles] << {
              id: product[:plu_code],
              name: lang == "en" ? product[:plu_description] : product[:plu_ar_description],
              images: [create_image_object(product[:image_path])],
              weight: index,
              description: product[:product_and_description],
              item_bundle_ids: [product[:plu_code]],
            }

            customization_option_ids += serialize_customization_options(product, category)

            mapped_menu[:items] << {
              id: product[:plu_code],
              images: [product[:image_path]],
              customization_option_ids: customization_option_ids,
              customization_ingredient_ids: [],
            }

            mapped_menu[:item_bundles] << {
              id: product[:plu_code],
              name: lang == "en" ? product[:plu_description] : product[:plu_ar_description],
              price: product[:price].to_f.to_s,
              weight: index,
              item_id: product[:plu_code],
              bundle_id: product[:plu_code],
            }
          end
        end

        def serialize_customization_options(product, category)
          customization_options_ids = []

          if product[:no_of_flavour].to_i > 0
            flavours_option_item_ids = []
            flavours_option_item_ids += serialize_falvours(product, category)
            falvour_id = "Flavours-#{category[:category_code]}-#{product[:plu_code]}"
            mapped_menu[:customization_options] << {
              id: falvour_id,
              name: "Flavours",
              images: [],
              weight: 2,
              max_selection: product[:no_of_flavour].to_i,
              min_selection: product[:min_flavour].to_i,
              customization_option_item_ids: flavours_option_item_ids,
            }

            customization_options_ids << falvour_id
          end

          if product[:no_of_topping].to_i > 0
            toppings_option_item_ids = []
            toppings_option_item_ids += serialize_toppings(product, category)
            topping_id = "Toppings-#{category[:category_code]}-#{product[:plu_code]}"
            mapped_menu[:customization_options] << {
              id: topping_id,
              name: "Toppings",
              images: [],
              weight: 1,
              max_selection: product[:no_of_topping].to_i,
              min_selection: product[:min_topping].to_i,
              customization_option_item_ids: toppings_option_item_ids,
            }

            customization_options_ids << topping_id
          end

          customization_options_ids
        end

        def serialize_falvours(product, category)
          category[:flavours].map.with_index do |flavour, index|
            id = "#{category[:category_code]}-#{product[:plu_code]}-#{flavour[:flavour_code]}"

            mapped_menu[:customization_option_items] << {
              id: id,
              name: lang == "en" ? flavour[:flavour_description] : flavour[:arabic_description],
              price: "0.0",
              weight: index,
              calories: flavour[:calories],
              default_selected: false, # TODO
              customization_option_id: "Flavours-#{category[:category_code]}-#{product[:plu_code]}",
              item_id: flavour[:flavour_code],
            }

            add_item(mapped_menu, {
              id: flavour[:flavour_code],
              images: [],
              customization_option_ids: [],
              customization_ingredient_ids: [],
            })

            id
          end
        end

        def serialize_toppings(product, category)
          category[:toppings].map.with_index do |topping, index|
            id = "Flavours-#{category[:category_code]}-#{product[:plu_code]}-#{topping[:topping_code]}"

            mapped_menu[:customization_option_items] << {
              id: id,
              name: lang == "en" ? topping[:topping_description] : topping[:arabic_description],
              price: "0.0",
              weight: index,
              calories: topping[:calories],
              default_selected: false, # TODO
              customization_option_id: "Toppings-#{category[:category_code]}-#{product[:plu_code]}",
              item_id: topping[:topping_code],
            }
            add_item(mapped_menu, {
              id: topping[:topping_code],
              images: [],
              customization_option_ids: [],
              customization_ingredient_ids: [],
            })

            id
          end
        end

        def product_ids(category)
          category[:products].map do |product|
            product[:plu_code]
          end
        end

        def add_item(mapped_menu, item)
          @item_ids ||= SortedSet.new
          return if @item_ids.include? item[:id]
          @item_ids.add item[:id]
          mapped_menu[:items] << item
        end

        def create_image_object(image_url)
          {
            "large": image_url,
            "micro": image_url,
            "small": image_url,
            "thumb": image_url,
            "medium": image_url,
          }
        end
      end
    end
  end
end
