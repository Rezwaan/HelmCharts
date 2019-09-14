module Integrations
  module Foodics
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
          catalog[:categories].each do |key, category|
            serialize_category(category)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_category(category)
          mapped_menu[:categories] << {
            id: category["hid"],
            name: category["name"][lang],
            weight: category["index"],
            product_ids: product_ids(category),
          }
        end

        def serialize_products(category)
          category[:products].each do |product|
            customization_option_ids = []

            mapped_menu[:products] << {
              id: product["hid"],
              name: product["name"][lang],
              images: product["image_path"].blank? ? [] : [create_image_object(product["image_path"])],
              weight: product["index"],
              bundle_ids: [product["hid"]],
              description: product["description"][lang],
            }

            mapped_menu[:bundles] << {
              id: product["hid"],
              name: product["name"][lang],
              images: product["image_path"].blank? ? [] : [create_image_object(product["image_path"])],
              weight: product["index"],
              description: product["description"][lang],
              item_bundle_ids: item_bundle_ids(product),
            }

            customization_option_ids += serialize_customization_options(product)

            mapped_menu[:items] << {
              id: product["hid"],
              images: product["image_path"].blank? ? [] : [product["image_path"]],
              customization_option_ids: customization_option_ids,
              customization_ingredient_ids: [],
            }

            product["sizes"].each do |size|
              mapped_menu[:item_bundles] << {
                id: size["hid"],
                name: size["name"][lang],
                price: size["price"].to_s,
                weight: size["index"],
                item_id: product["hid"],
                bundle_id: product["hid"],
              }
            end
          end
        end

        def serialize_customization_options(product)
          product["modifiers"].map do |modifier|
            id = modifier["hid"]
            mapped_menu[:customization_options] << {
              id: id,
              name: catalog[:modifiers][id]["name"][lang],
              images: [],
              weight: modifier["relationship_data"]["index"],
              min_selection: modifier["relationship_data"]["minimum_options"].to_i,
              max_selection: modifier["relationship_data"]["maximum_options"].to_i,
              customization_option_item_ids: serialize_customization_option_items(modifier),
            }

            id
          end
        end

        def serialize_customization_option_items(modifier)
          same_limits = modifier["relationship_data"]["minimum_options"].to_i == 1 && modifier["relationship_data"]["maximum_options"].to_i == 1
          modifier_id = modifier["hid"]
          option_items = []

          catalog[:modifiers][modifier_id]["options"].each do |modifier_option|
            next if modifier["relationship_data"]["excluded_options"].include?(modifier_option["hid"])

            id = modifier_option["hid"]
            mapped_menu[:customization_option_items] << {
              id: id,
              item_id: id,
              name: modifier_option["name"][lang],
              price: modifier_option["price"].to_s,
              weight: modifier_option["index"],
              default_selected: (same_limits && modifier_option["index"] == 0),
              customization_option_id: modifier_id,
            }

            option_items << id
          end

          option_items
        end

        def product_ids(category)
          category[:products].map do |product|
            product["hid"]
          end
        end

        def item_bundle_ids(product)
          product["sizes"].map do |size|
            size["hid"]
          end
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
