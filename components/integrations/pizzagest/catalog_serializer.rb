module Integrations
  module Pizzagest
    class CatalogSerializer
      def initialize(catalog:, locale: :en)
        @catalog = catalog
        @locale = locale
      end

      def menu
        @result = {
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

        @item_ids = SortedSet.new

        all_customization_options = {}
        all_customization_option_items = {}
        @catalog.reject { |category| category["Visible"] == "N" }.each do |category|
          product_ids = []

          category["Products"].each do |key, product|
            product_customization_options = []
            product_recipe_required_toppings = []
            product_recipe_optional_toppings = []
            product_recipe_required_sauces = []
            product_recipe_optional_sauces = []
            product_recipe_required_doughs = []
            product_recipe_optional_doughs = []
            customization_option_ids = []

            if product["Doughs"] && category["Doughs"]

              customization_option_items = []
              product["Doughs"].each do |dough|
                if dough["Required"] == "S"
                  product_recipe_required_doughs << "+#{dough["ToppingCode"]}"
                else
                  product_recipe_optional_doughs << dough["ToppingCode"]
                end
              end

              if product_recipe_required_doughs.empty?
                category["Doughs"].each_with_index do |dough, index|
                  is_optional = product_recipe_optional_doughs.include?(dough["ToppingCode"])
                  customization_option_items << {
                    id: "+#{dough["ToppingCode"]}",
                    name: dough["ToppingName"],
                    price: dough["Price"].to_s,
                    weight: index,
                    default_selected: is_optional,
                    item_id: dough["ToppingCode"],
                  }

                  add_item({
                    id: dough["ToppingCode"],
                    images: [],
                    customization_option_ids: [],
                    customization_ingredient_ids: [],
                  })
                end
                customization_option = {
                  id: "Doughs-#{category["FamilyCode"]}",
                  name: I18n.t("integrations.pizzagest.dough", locale: @locale),
                  images: [],
                  weight: 1,
                  max_selection: 1,
                  min_selection: 1,
                }
                id = generate_customization_option_id(customization_option, customization_option_items)
                customization_option_items.each do |customization_option_item|
                  customization_option_item[:id] = id + "/" + customization_option_item[:id]
                  customization_option_item[:customization_option_id] = id
                  all_customization_option_items[customization_option_item[:id]] = customization_option_item
                end
                customization_option[:id] = id
                customization_option[:customization_option_item_ids] = customization_option_items.pluck(:id)
                customization_option_ids << id
                all_customization_options[id] = customization_option

              end
            end

            if product["Sauces"] && category["Sauces"]

              customization_option_items = []
              product["Sauces"].each do |sauce|
                # Sometimes the sauce in product does not exist in category list of sauces. In that case we should just ignore it.
                next if category["Sauces"].find { |category_sauce| category_sauce["ToppingCode"] == sauce["ToppingCode"] }.blank?
                if sauce["Required"] == "S"
                  product_recipe_required_sauces << sauce["ToppingCode"]
                else
                  product_recipe_optional_sauces << sauce["ToppingCode"]
                end
              end

              if category["Sauces"].count > (product_recipe_required_sauces.count + product_recipe_optional_sauces.count) && product_recipe_required_sauces.count < 2
                category["Sauces"].each_with_index do |sauce, index|
                  next if product_recipe_required_sauces.include?(sauce["ToppingCode"])
                  is_optional = product_recipe_optional_sauces.include?(sauce["ToppingCode"])
                  customization_option_items << {
                    id: is_optional ? sauce["ToppingCode"] : "+" + sauce["ToppingCode"],
                    name: sauce["ToppingName"],
                    price: is_optional ? "0" : sauce["Price"].to_s,
                    weight: index,
                    default_selected: is_optional,
                    item_id: sauce["ToppingCode"],
                  }

                  add_item({
                    id: sauce["ToppingCode"],
                    images: [],
                    customization_option_ids: [],
                    customization_ingredient_ids: [],
                  })
                end
                customization_option = {
                  id: "Sauces-#{category["FamilyCode"]}",
                  name: I18n.t("integrations.pizzagest.sauce", locale: @locale),
                  images: [],
                  weight: 2,
                  max_selection: 2 - product_recipe_required_sauces.count,
                  min_selection: 0,
                }
                id = generate_customization_option_id(customization_option, customization_option_items)
                customization_option_items.each do |customization_option_item|
                  customization_option_item[:id] = id + "/" + customization_option_item[:id]
                  customization_option_item[:customization_option_id] = id
                  all_customization_option_items[customization_option_item[:id]] = customization_option_item
                end
                customization_option[:id] = id
                customization_option[:customization_option_item_ids] = customization_option_items.pluck(:id)
                customization_option_ids << id
                all_customization_options[id] = customization_option

              end
            end

            if product["Topping"] && category["Topping"]
              customization_option_items = []
              product["Topping"].each do |topping|
                if topping["Required"] == "S"
                  product_recipe_required_toppings << topping["ToppingCode"]
                else
                  product_recipe_optional_toppings << topping["ToppingCode"]
                end
              end

              if category["Topping"].count > (product_recipe_required_toppings.count + product_recipe_optional_toppings.count)
                category["Topping"].each_with_index do |topping, index|
                  next if product_recipe_required_toppings.include?(topping["ToppingCode"])
                  next if product_recipe_optional_toppings.include?(topping["ToppingCode"])
                  customization_option_items << {
                    id: "+" + topping["ToppingCode"],
                    name: topping["ToppingName"],
                    price: topping["Price"].to_s,
                    weight: index,
                    default_selected: false,
                    item_id: topping["ToppingCode"],
                  }
                  add_item({
                    id: topping["ToppingCode"],
                    images: [],
                    customization_option_ids: [],
                    customization_ingredient_ids: [],
                  })
                end

                customization_option = {
                  id: "Topping-#{category["FamilyCode"]}",
                  name: I18n.t("integrations.pizzagest.topping", locale: @locale),
                  images: [],
                  weight: 3,
                  max_selection: product["MaxTopping"].to_i - product_recipe_required_toppings.count,
                  min_selection: 0,
                }

                id = generate_customization_option_id(customization_option, customization_option_items)
                customization_option_items.each do |customization_option_item|
                  customization_option_item[:id] = id + "/" + customization_option_item[:id]
                  customization_option_item[:customization_option_id] = id
                  all_customization_option_items[customization_option_item[:id]] = customization_option_item
                end
                customization_option[:id] = id
                customization_option[:customization_option_item_ids] = customization_option_items.pluck(:id)
                customization_option_ids << id
                all_customization_options[id] = customization_option

                if product_recipe_optional_toppings.count > 0
                  customization_option_items = []
                  product_recipe_optional_toppings.each_with_index do |toppingCode, index|
                    topping = product["Topping"].find { |topping| topping["ToppingCode"] == toppingCode }
                    customization_option_items << {
                      id: "-" + topping["ToppingCode"],
                      name: I18n.t("integrations.pizzagest.remove_topping", {locale: @locale, topping: topping["ToppingName"]}),
                      price: "0",
                      weight: index,
                      default_selected: false,
                      item_id: "Remove" + topping["ToppingCode"],
                    }
                    add_item({
                      id: "Remove" + topping["ToppingCode"],
                      images: [],
                      customization_option_ids: [],
                      customization_ingredient_ids: [],
                    })
                  end

                  customization_option = {
                    id: "RemoveTopping-#{category["FamilyCode"]}",
                    name: I18n.t("integrations.pizzagest.remove_header", locale: @locale),
                    images: [],
                    weight: 4,
                    max_selection: product_recipe_optional_toppings.count,
                    min_selection: 0,
                  }
                  id = generate_customization_option_id(customization_option, customization_option_items)

                  customization_option_items.each do |customization_option_item|
                    customization_option_item[:id] = id + "/" + customization_option_item[:id]
                    customization_option_item[:customization_option_id] = id
                    all_customization_option_items[customization_option_item[:id]] = customization_option_item
                  end
                  customization_option[:id] = id
                  customization_option[:customization_option_item_ids] = customization_option_items.pluck(:id)
                  customization_option_ids << id
                  all_customization_options[id] = customization_option
                end
              end
            end

            product_id = {
              code: product["ProductCode"],
              family: category["FamilyCode"],
              required_topping: product_recipe_required_doughs.sort,
              preselected_topping: product_recipe_optional_sauces.sort,
              removable_topping: product_recipe_optional_toppings.sort,
            }.to_json

            @result[:products] << {
              "id": product_id,
              "name": product["ProductName"],
              "images": [create_image_object(product["ImageUrl"])],
              "weight": product["OrderAt"].to_i,
              "bundle_ids": [product_id],
              "description": product["ProductDescription"].to_s,
            }

            @result[:bundles] << {
              "id": product_id,
              "name": product["ProductName"],
              "images": [create_image_object(product["ImageUrl"])],
              "weight": product["OrderAt"].to_i,
              "description": product["ProductDescription"].to_s,
              "item_bundle_ids": [product_id],
            }

            @result[:item_bundles] << {
              "id": product_id,
              "name": product["ProductName"],
              "price": product["Price"].to_s,
              "weight": product["OrderAt"].to_i,
              "item_id": product["ProductCode"],
              "bundle_id": product_id,
            }

            add_item({
              id: product["ProductCode"],
              images: [product["ImageUrl"]],
              customization_option_ids: customization_option_ids,
              customization_ingredient_ids: [],
            })

            product_ids << product_id
          end

          @result[:categories] << {
            "id": category["FamilyCode"],
            "name": category["FamilyName"],
            "weight": category["Order"].to_i,
            "product_ids": product_ids,
          }
        end

        @result[:customization_options] = all_customization_options.values
        @result[:customization_option_items] = all_customization_option_items.values
        @result
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

      def generate_customization_option_id(customization_option, customization_option_items)
        {
          customization_option_id: customization_option[:id],
          customization_option_item_ids: customization_option_items.pluck(:id).sort,
          selected_customization_option_item_ids: customization_option_items.select { |a| a[:default_selected] }.pluck(:id).sort,
        }.to_json
      end

      def add_item(item)
        return if @item_ids.include? item[:id]
        @item_ids.add item[:id]
        @result[:items] << item
      end
    end
  end
end
