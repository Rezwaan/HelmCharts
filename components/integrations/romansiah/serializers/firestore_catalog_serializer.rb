module Integrations
  module Romansiah
    module Serializers
      class FirestoreCatalogSerializer
        attr_reader :catalog_en, :catalog_ar, :mapped_menu

        def initialize(catalog_en:, catalog_ar:)
          @catalog_en = catalog_en.with_indifferent_access
          @catalog_ar = catalog_ar.with_indifferent_access
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
          catalog_en[:categories].each_with_index do |(key, category), index|
            serialize_category(category, index)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_products(category)
          category[:products].each_with_index do |product, index|
            next if product[:is_deleted]

            product_id = product[:id]
            product_ar = get_product_arabic_version(category, index)
            mapped_menu[:products][product_id] = {
              id: product_id,
              name: item_name(product) || " ",
              name_ar: item_name(product_ar, product) || " ",
              reference_name: product_id.to_s,
              images: product[:images].empty? ? {} : image_objects(product[:images]),
              weight: index,
              bundle_ids: {"#{product_id}": product_id},
              description: item_description(product) || " ",
              description_ar: item_description(product_ar, product) || " ",
            }

            mapped_menu[:bundles][product_id] = {
              id: product_id,
              name: item_name(product) || " ",
              name_ar: item_name(product_ar, product) || " ",
              reference_name: product_id.to_s,
              images: product[:images].empty? ? {} : image_objects(product[:images]),
              weight: index,
              description: item_description(product) || " ",
              description_ar: item_description(product_ar, product) || " ",
              item_bundle_ids: {"#{product_id}": product_id},
            }

            mapped_menu[:items][product_id] = {
              id: product_id,
              reference_name: product_id.to_s,
              images: product[:images].empty? ? {} : image_objects(product[:images]),
              customization_option_ids: serialize_customization_options(product, category, index),
              customization_ingredient_ids: {},
            }

            mapped_menu[:item_bundles][product_id] = {
              id: product_id,
              name: item_name(product) || " ",
              name_ar: item_name(product_ar, product) || " ",
              description: item_description(product) || " ",
              description_ar: item_description(product_ar, product) || " ",
              price: product[:price].to_s,
              weight: index,
              item_id: product_id,
              bundle_id: product_id,
            }
          end
        end

        def serialize_customization_options(product, category, index)
          return {} if product[:associated_products].empty?

          option_id = product[:associated_products][0][:parent_attribute_mapping_id]
          product_ar = get_product_arabic_version(category, index)

          mapped_menu[:customization_options][option_id] = {
            id: option_id,
            name: item_name(product) || " ",
            name_ar: item_name(product_ar, product) || " ",
            reference_name: option_id.to_s,

            # HACK: We don't really use customization_option.images, but since
            # Swyft iOS expects them to be an array of strings and Swyft Android
            # expects it to be an object, we'll send it as an empty object
            # (which Dome's Swyft catalog serializer should turn to an
            # empty array) for now to avoid breaking Swyft iOS.
            images: {},
            # images: product[:images].empty? ? {} : image_objects(product[:images]),

            max_selection: 1,
            min_selection: 1,
            customization_option_item_ids: serialize_customization_option_items(product, category, index),
          }

          {
            "#{option_id}": {
              id: option_id,
              weight: 0
            }
          }
        end

        def serialize_customization_option_items(product, category, index)
          option_items = {}
          product_ar = get_product_arabic_version(category, index)

          product[:associated_products].each_with_index do |assoc_product, index|
            id = assoc_product[:id]
            assoc_product_ar = product_ar[:associated_products][index]

            mapped_menu[:customization_option_items][id] = {
              id: id,
              name: item_name(assoc_product) || " ",
              name_ar: item_name(assoc_product_ar, assoc_product) || " ",
              price: assoc_product[:price_adjustment].to_s,
              weight: index,
              default_selected: (index == 0),
              customization_option_id: assoc_product[:parent_attribute_mapping_id],
              item_id: id,
            }

            add_item({
              id: id,
              reference_name: id.to_s,
              images: {},
              customization_option_ids: {},
              customization_ingredient_ids: {},
            })

            option_items[id] = id
          end

          option_items
        end

        def serialize_category(category, weight)
          category_id = category[:id]
          category_ar = get_catagory_arabic_version(category)

          mapped_menu[:categories][category_id] = {
            id: category_id,
            name: item_name(category) || " ",
            name_ar: item_name(category_ar, category) || " ",
            weight: weight,
            product_ids: product_ids(category),
          }
        end

        def product_ids(category)
          category[:products].each_with_object({}) do |product, hash|
            product_id = product[:id]
            hash[product_id] = product_id
          end
        end

        def item_name(item, fallback = nil)
          return item[:name] if item[:name].present?

          fallback.dig(:name)
        end

        def item_description(item, fallback = nil)
          return item[:short_description] if item[:short_description].present?

          fallback&.dig(:short_description)
        end

        def add_item(item)
          @item_ids ||= SortedSet.new
          return if @item_ids.include? item[:id]
          @item_ids.add item[:id]
          mapped_menu[:items][item[:id]] = item
        end

        def get_catagory_arabic_version(category)
          catalog_ar[:categories][category[:id]]
        end

        def get_product_arabic_version(category, product_index)
          catalog_ar[:categories][category[:id]][:products][product_index]
        end

        def image_objects(images)
          images.each_with_object({}) do |image, hash|
            hash[SecureRandom.uuid] = image[:src]
          end
        end
      end
    end
  end
end
