module Integrations
  module Romansiah
    module Serializers
      class CatalogSerializer
        attr_reader :catalog, :mapped_menu
        def initialize(catalog:)
          @catalog = catalog
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
          catalog[:categories].each_with_index do |(key, category), index|
            serialize_category(category, index)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_category(category, index)
          mapped_menu[:categories] << {
            id: category["id"],
            name: category["name"],
            weight: index + 1,
            product_ids: product_ids(category),
          }
        end

        def serialize_products(category)
          category[:products].each_with_index do |product, index|
            next if product["is_deleted"]

            mapped_menu[:products] << {
              id: product["id"],
              name: product["name"],
              images: create_image_objects(product["images"]),
              weight: index + 1,
              bundle_ids: [product["id"]],
              description: product["short_description"],
            }

            mapped_menu[:bundles] << {
              id: product["id"],
              name: product["name"],
              images: create_image_objects(product["images"]),
              weight: index + 1,
              description: product["short_description"],
              item_bundle_ids: [product["id"]],
            }
            options = []

            mapped_menu[:items] << {
              id: product["id"],
              images: images_in_str(product["images"]),
              customization_option_ids: serialize_customization_options(product),
              customization_ingredient_ids: [],
            }

            mapped_menu[:item_bundles] << {
              id: product["id"],
              name: product["name"],
              price: "0",
              weight: index + 1,
              item_id: product["id"],
              bundle_id: product["id"],
            }
          end
        end

        def serialize_customization_options(product)
          return [] if product["associated_products"].empty?

          option_id = product["associated_products"][0]["parent_attribute_mapping_id"]
          mapped_menu[:customization_options] << {
            id: option_id,
            name: product["name"],
            images: images_in_str(product["images"]),
            weight: 1,
            min_selection: 1,
            max_selection: 1,
            customization_option_item_ids: serialize_customization_option_items(product),
          }

          [option_id]
        end

        def serialize_customization_option_items(product)
          option_items = []

          product["associated_products"].each_with_index do |assoc_product, index|
            id = assoc_product["id"]
            mapped_menu[:customization_option_items] << {
              id: id,
              item_id: id,
              name: assoc_product["name"],
              price: assoc_product["price_adjustment"].to_s,
              weight: index + 1,
              default_selected: (index == 0),
              customization_option_id: assoc_product["parent_attribute_mapping_id"],
            }

            option_items << id
          end

          option_items
        end

        def product_ids(category)
          category[:products].map do |product|
            product["id"]
          end
        end

        def item_bundle_ids(product)
          product["associated_products"].map do |assoc_product|
            assoc_product["id"]
          end
        end

        def create_image_objects(images)
          images.map do |image_url|
            {
              "large": image_url["src"],
              "micro": image_url["src"],
              "small": image_url["src"],
              "thumb": image_url["src"],
              "medium": image_url["src"],
            }
          end
        end

        def images_in_str(images)
          images.map do |image_url|
            image_url["src"]
          end
        end
      end
    end
  end
end
