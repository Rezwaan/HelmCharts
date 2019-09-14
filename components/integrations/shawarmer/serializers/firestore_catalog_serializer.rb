module Integrations
  module Shawarmer
    module Serializers
      class FirestoreCatalogSerializer
        attr_reader :catalog, :mapped_menu

        def initialize(catalog:)
          @catalog = catalog.with_indifferent_access
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
          catalog[:categories].each_with_index do |category, index|
            serialize_category(category, index)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_category(category, weight)
          category_id = category[:Id]
          mapped_menu[:categories][category_id] = {
            id: category_id,
            name: item_name(category, "en") || " ",
            name_ar: item_name(category, "ar") || " ",
            weight: category[:CategorySequence],
            product_ids: product_ids(category),
          }
        end

        def serialize_products(category)
          category[:Items].each_with_index do |item, index|
            item_id = item[:ItemId]
            product_id = item[:Id]

            mapped_menu[:products][product_id] = {
              id: product_id,
              name: item_name(item, "en") || " ",
              name_ar: item_name(item, "ar") || " ",
              reference_name: product_id.to_s,
              images: item[:ImageURL].blank? ? {} : {"#{SecureRandom.uuid}": item[:ImageURL]},
              weight: item[:CategoryItemSequence],
              bundle_ids: {"#{product_id}": product_id},
              description: item_description(item, "en") || " ",
              description_ar: item_description(item, "ar") || " ",
            }

            mapped_menu[:bundles][product_id] = {
              id: product_id,
              name: item_name(item, "en") || " ",
              name_ar: item_name(item, "ar") || " ",
              reference_name: item_id.to_s,
              images: item[:ImageURL].blank? ? {} : {"#{SecureRandom.uuid}": item[:ImageURL]},
              weight: item[:CategoryItemSequence],
              description: item_description(item, "en") || " ",
              description_ar: item_description(item, "ar") || " ",
              item_bundle_ids: {"#{product_id}": product_id},
            }

            mapped_menu[:items][item_id] = {
              id: item_id,
              reference_name: item_id.to_s,
              images: item[:ImageURL].blank? ? {} : {"#{SecureRandom.uuid}": item[:ImageURL]},
              customization_option_ids: serialize_customization_options(item),
              customization_ingredient_ids: {},
            }

            mapped_menu[:item_bundles][product_id] = {
              id: product_id,
              name: item_name(item, "en"),
              name_ar: item_name(item, "ar"),
              description: item_description(item, "en") || " ",
              description_ar: item_description(item, "ar") || " ",
              price: item[:ItemPrice].to_s,
              weight: item[:CategoryItemSequence],
              item_id: item_id,
              bundle_id: product_id,
            }
          end
        end

        def serialize_customization_options(item)
          customization_options_ids = {}
          item[:Modifiers].each_with_index do |modifier, index|
            id = modifier[:Modifierid]
            mapped_menu[:customization_options][id] = {
              id: id,
              name: item_name(modifier, "en") || " ",
              name_ar: item_name(modifier, "ar") || " ",
              reference_name: id.to_s,
              images: {},
              max_selection: modifier[:Max].to_i,
              min_selection: modifier[:Min].to_i,
              customization_option_item_ids: serialize_customization_option_items(modifier),
            }

            customization_options_ids[id] = {
              id: id,
              weight: index
            }
          end

          customization_options_ids
        end

        def serialize_customization_option_items(modifier)
          result = {}
          same_limits = modifier[:Max].to_i == 1 && modifier[:Min].to_i == 1

          modifier[:ModifierItems].each_with_index do |modifier_item, index|
            item_id = modifier_item[:ItemId]
            id = "#{modifier_item[:Id]}/#{modifier_item[:ItemId]}"

            mapped_menu[:customization_option_items][id] = {
              id: id,
              name: item_name(modifier_item, "en") || " ",
              name_ar: item_name(modifier_item, "ar") || " ",
              price: modifier_item["ItemPrice"],
              weight: index,
              default_selected: (same_limits && index == 0),
              customization_option_id: modifier_item[:ModifierId],
              item_id: item_id,
            }

            add_item({
              id: item_id,
              reference_name: item_id.to_s,
              images: {},
              customization_option_ids: {},
              customization_ingredient_ids: {},
            })

            result[id] = id
          end

          result
        end

        def product_ids(category)
          category[:Items].each_with_object({}) do |product, hash|
            product_id = product[:Id]
            hash[product_id] = product_id
          end
        end

        def item_name(item, lang)
          return item[:ArabicName] if lang == "ar" && item[:ArabicName].present?

          item[:EnglishName]
        end

        def item_description(item, lang)
          return item[:DescriptionArabic] if lang == "ar" && item[:DescriptionArabic].present?

          item[:DescriptionEnglish]
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
