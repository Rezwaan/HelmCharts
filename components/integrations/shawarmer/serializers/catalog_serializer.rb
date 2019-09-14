module Integrations
  module Shawarmer
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
          catalog["categories"].each do |category|
            serialize_category(category)
            serialize_products(category)
          end

          mapped_menu
        end

        private

        def serialize_category(category)
          mapped_menu[:categories] << {
            id: category["Id"],
            name: item_name(category, lang),
            weight: category["CategorySequence"],
            product_ids: product_ids(category),
          }
        end

        def serialize_products(category)
          category["Items"].each do |item|
            customization_option_ids = []

            mapped_menu[:products] << {
              id: item["Id"],
              name: item_name(item, lang),
              images: item["ImageURL"].blank? ? [] : [create_image_object(item["ImageURL"])],
              weight: item["CategoryItemSequence"],
              bundle_ids: [item["Id"]],
              description: item_description(item, lang),
            }

            mapped_menu[:bundles] << {
              id: item["Id"],
              name: item_name(item, lang),
              images: item["ImageURL"].blank? ? [] : [create_image_object(item["ImageURL"])],
              weight: item["CategoryItemSequence"],
              description: item_description(item, lang),
              item_bundle_ids: [item["Id"]],
            }

            mapped_menu[:item_bundles] << {
              id: item["Id"],
              name: item_name(item, lang),
              price: item["ItemPrice"].to_s,
              weight: item["CategoryItemSequence"],
              item_id: item["ItemId"],
              bundle_id: item["Id"],
            }

            add_item({
              id: item["ItemId"],
              images: item["ImageURL"].blank? ? [] : [item["ImageURL"]],
              customization_option_ids: customization_option_ids,
              customization_ingredient_ids: [],
            })

            # TODO: Remove this line?
            customization_option_ids += serialize_customization_options(item)
          end
        end

        def serialize_customization_options(item)
          item["Modifiers"].map_with_index do |modifier, index|
            id = modifier["Modifierid"]
            add_customization_option({
              id: id,
              name: item_name(modifier, lang),
              images: [],
              weight: index + 1,
              max_selection: modifier["Max"].to_i,
              min_selection: modifier["Min"].to_i,
              customization_option_item_ids: serialize_customization_option_items(modifier),
            })

            id
          end
        end

        def serialize_customization_option_items(modifier)
          same_limits = modifier["Max"].to_i == 1 && modifier["Min"].to_i == 1

          modifier["ModifierItems"].map.with_index do |modifier_item, index|
            id = "#{modifier_item["Id"]}/#{modifier_item["ItemId"]}"
            mapped_menu[:customization_option_items] << {
              id: id,
              item_id: modifier_item["ItemId"],
              name: item_name(modifier_item, lang),
              price: modifier_item["ItemPrice"].to_s,
              weight: index,
              default_selected: (same_limits && index == 0),
              customization_option_id: modifier_item["ModifierId"],
            }

            add_item({
              id: item["ItemId"],
              images: [],
              customization_option_ids: [],
              customization_ingredient_ids: [],
            })

            id
          end
        end

        def product_ids(category)
          category["Items"].map do |item|
            item["Id"]
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

        def item_name(item, lang)
          return item["ArabicName"] if lang == "ar" && item["ArabicName"].present?

          item["EnglishName"]
        end

        def item_description(item, lang)
          return item["DescriptionArabic"] if lang == "ar" && item["DescriptionArabic"].present?

          item["DescriptionEnglish"]
        end

        def add_item(item)
          @item_ids ||= SortedSet.new
          return if @item_ids.include? item[:id]
          @item_ids.add item[:id]
          mapped_menu[:items] << item
        end

        def add_customization_option(customization_option)
          @customization_option_ids ||= SortedSet.new
          return if @customization_option_ids.include? customization_option[:id]
          @customization_option_ids.add customization_option[:id]
          mapped_menu[:customization_options] << customization_option
        end
      end
    end
  end
end
