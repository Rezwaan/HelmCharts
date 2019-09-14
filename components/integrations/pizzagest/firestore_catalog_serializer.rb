module Integrations
  module Pizzagest
    class FirestoreCatalogSerializer
      attr_reader :catalog_en, :catalog_ar, :mapped_menu

      def initialize(catalog_en:, catalog_ar:)
        @catalog_en = catalog_en
        @catalog_ar = catalog_ar
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
        all_customization_options = {}
        all_customization_option_items = {}
        catalog_en.reject { |category| category["Visible"] == "N" }.each_with_index do |category, category_index|
          product_ids = {}
          category["Products"].each do |product_key, product|
            product_customization_options = {}
            product_recipe_required_toppings = []
            product_recipe_optional_toppings = []
            product_recipe_required_sauces = []
            product_recipe_optional_sauces = []
            product_recipe_required_doughs = []
            product_recipe_optional_doughs = []
            customization_option_ids = {}

            if product["Doughs"] && category["Doughs"]
              customization_option_items = {}
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
                  customization_option_items["+#{dough["ToppingCode"]}"] = {
                    id: "+#{dough["ToppingCode"]}",
                    name: dough["ToppingName"],
                    name_ar: dough["ToppingName"],
                    price: dough["Price"].to_s,
                    weight: index,
                    default_selected: is_optional,
                    item_id: dough["ToppingCode"],
                  }

                  add_item({
                    id: dough["ToppingCode"],
                    reference_name: dough["ToppingCode"],
                    images: {},
                    customization_option_ids: {},
                    customization_ingredient_ids: {},
                  })
                end
                customization_option_id = "Doughs-#{category["FamilyCode"]}"
                customization_option = {
                  id: customization_option_id,
                  name: I18n.t("integrations.pizzagest.dough", locale: :en) || " ",
                  name_ar: I18n.t("integrations.pizzagest.dough", locale: :ar) || " ",
                  reference_name: customization_option_id,
                  images: {},
                  max_selection: 1,
                  min_selection: 1,
                  customization_option_item_ids: {},
                }

                id = generate_customization_option_id(customization_option, customization_option_items)
                customization_option_items.each do |key, customization_option_item|
                  customization_option_item[:id] = id + "/" + customization_option_item[:id]
                  customization_option_item[:customization_option_id] = id
                  all_customization_option_items[key] = customization_option_item
                end

                customization_option[:id] = id
                customization_option_items.each do |key, value|
                  customization_option[:customization_option_item_ids][key] = key
                end
                customization_option_ids[id] = {
                  id: id,
                  weight: 1
                }
                all_customization_options[id] = customization_option
              end
            end

            if product["Sauces"] && category["Sauces"]
              customization_option_items = {}
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
                  item_id = is_optional ? sauce["ToppingCode"] : "+" + sauce["ToppingCode"]
                  customization_option_items[item_id] = {
                    id: "+#{sauce["ToppingCode"]}",
                    name: sauce["ToppingName"],
                    name_ar: sauce["ToppingName"],
                    price: is_optional ? "0" : sauce["Price"].to_s,
                    weight: index,
                    default_selected: is_optional,
                    item_id: sauce["ToppingCode"],
                  }

                  add_item({
                    id: sauce["ToppingCode"],
                    reference_name: sauce["ToppingCode"],
                    images: {},
                    customization_option_ids: {},
                    customization_ingredient_ids: {},
                  })
                end
                customization_option_id = "Sauces-#{category["FamilyCode"]}"
                customization_option = {
                  id: customization_option_id,
                  name: I18n.t("integrations.pizzagest.sauce", locale: :en),
                  name_ar: I18n.t("integrations.pizzagest.sauce", locale: :ar),
                  reference_name: customization_option_id,
                  images: {},
                  max_selection: 2 - product_recipe_required_sauces.count,
                  min_selection: 0,
                  customization_option_item_ids: {},
                }
                id = generate_customization_option_id(customization_option, customization_option_items)
                customization_option_items.each do |key, customization_option_item|
                  customization_option_item[:id] = id + "/" + customization_option_item[:id]
                  customization_option_item[:customization_option_id] = id
                  all_customization_option_items[key] = customization_option_item
                end

                customization_option[:id] = id
                customization_option_items.each do |key, value|
                  customization_option[:customization_option_item_ids][key] = key
                end
                customization_option_ids[id] = {
                  id: id,
                  weight: 2
                }
                all_customization_options[id] = customization_option
              end
            end

            if product["Topping"] && category["Topping"]
              customization_option_items = {}
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

                  customization_option_items["+#{topping["ToppingCode"]}"] = {
                    id: "+#{topping["ToppingCode"]}",
                    name: topping["ToppingName"],
                    name_ar: topping["ToppingName"],
                    price: topping["Price"].to_s,
                    weight: index,
                    default_selected: false,
                    item_id: topping["ToppingCode"],
                  }

                  add_item({
                    id: topping["ToppingCode"],
                    reference_name: topping["ToppingCode"],
                    images: {},
                    customization_option_ids: {},
                    customization_ingredient_ids: {},
                  })
                end

                customization_option_id = "Topping-#{category["FamilyCode"]}"
                customization_option = {
                  id: customization_option_id,
                  name: I18n.t("integrations.pizzagest.topping", locale: :en),
                  name_ar: I18n.t("integrations.pizzagest.topping", locale: :ar),
                  reference_name: customization_option_id,
                  images: {},
                  max_selection: product["MaxTopping"].to_i - product_recipe_required_toppings.count,
                  min_selection: 0,
                  customization_option_item_ids: {},
                }

                id = generate_customization_option_id(customization_option, customization_option_items)
                customization_option_items.each do |key, customization_option_item|
                  customization_option_item[:id] = id + "/" + customization_option_item[:id]
                  customization_option_item[:customization_option_id] = id
                  all_customization_option_items[key] = customization_option_item
                end

                customization_option[:id] = id
                customization_option_items.each do |key, value|
                  customization_option[:customization_option_item_ids][key] = key
                end
                customization_option_ids[id] = {
                  id: id,
                  weight: 3
                }
                all_customization_options[id] = customization_option

                if product_recipe_optional_toppings.count > 0
                  customization_option_items = {}
                  product_recipe_optional_toppings.each_with_index do |toppingCode, index|
                    topping = product["Topping"].find { |topping| topping["ToppingCode"] == toppingCode }
                    customization_option_items["+#{topping["ToppingCode"]}"] = {
                      id: "-#{topping["ToppingCode"]}",
                      name: I18n.t("integrations.pizzagest.remove_topping", {locale: :en, topping: topping["ToppingName"]}),
                      name_ar: I18n.t("integrations.pizzagest.remove_topping", {locale: :ar, topping: topping["ToppingName"]}),
                      price: "0",
                      weight: index,
                      default_selected: false,
                      item_id: "Remove" + topping["ToppingCode"],
                    }

                    add_item({
                      id: "Remove" + topping["ToppingCode"],
                      reference_name: "Remove" + topping["ToppingCode"],
                      images: {},
                      customization_option_ids: {},
                      customization_ingredient_ids: {},
                    })
                  end


                  customization_option_id = "RemoveTopping-#{category["FamilyCode"]}"
                  customization_option = {
                    id: customization_option_id,
                    name: I18n.t("integrations.pizzagest.remove_header", locale: :en),
                    name_ar: I18n.t("integrations.pizzagest.remove_header", locale: :ar),
                    reference_name: customization_option_id,
                    images: {},
                    max_selection: product_recipe_optional_toppings.count,
                    min_selection: 0,
                    customization_option_item_ids: {},
                  }

                  id = generate_customization_option_id(customization_option, customization_option_items)
                  customization_option_items.each do |key, customization_option_item|
                    customization_option_item[:id] = id + "/" + customization_option_item[:id]
                    customization_option_item[:customization_option_id] = id
                    all_customization_option_items[key] = customization_option_item
                  end

                  customization_option[:id] = id
                  customization_option_items.each do |key, value|
                    customization_option[:customization_option_item_ids][key] = key
                  end
                  customization_option_ids[id] = {
                    id: id,
                    weight: 4
                  }
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

            arabic_product = get_product_in_arabic(category["FamilyCode"], product_key)

            mapped_menu[:products][product_id] = {
              id: product_id,
              name: product["ProductName"],
              name_ar: arabic_product["ProductName"],
              reference_name: product_id,
              images: product["ImageUrl"].blank? ? {} : {"#{SecureRandom.uuid}": product["ImageUrl"]},
              weight: product["OrderAt"].to_i,
              bundle_ids: {"#{product_id}": product_id},
              description: product["ProductDescription"].to_s,
              description_ar: arabic_product["ProductDescription"].to_s,
            }

            mapped_menu[:bundles][product_id] = {
              id: product_id,
              name: product["ProductName"],
              name_ar: arabic_product["ProductName"],
              reference_name: product_id,
              images: product["ImageUrl"].blank? ? {} : {"#{SecureRandom.uuid}": product["ImageUrl"]},
              weight: product["OrderAt"].to_i,
              description: product["ProductDescription"].to_s,
              description_ar: arabic_product["ProductDescription"].to_s,
              item_bundle_ids: {"#{product_id}": product_id},
            }

            mapped_menu[:item_bundles][product_id] = {
              id: product_id,
              name: product["ProductName"],
              name_ar: product["ProductName"],
              description: product["ProductDescription"].to_s,
              description_ar: arabic_product["ProductDescription"].to_s,
              price: product["Price"].to_s,
              weight: product["OrderAt"].to_i,
              item_id: product["ProductCode"],
              bundle_id: product_id,
            }

            add_item({
              id: product["ProductCode"],
              reference_name: product["ProductCode"],
              images: product["ImageUrl"].blank? ? {} : {"#{SecureRandom.uuid}": product["ImageUrl"]},
              customization_option_ids: customization_option_ids,
              customization_ingredient_ids: {},
            })

            product_ids[product_id] = product_id
          end

          mapped_menu[:categories][category["FamilyCode"]] = {
            id: category["FamilyCode"],
            name: category["FamilyName"],
            name_ar: category["FamilyName"],
            weight: category["Order"].to_i,
            product_ids: product_ids,
          }
        end
        mapped_menu[:customization_options] = all_customization_options
        mapped_menu[:customization_option_items] = all_customization_option_items
        mapped_menu
      end

      private

      def generate_customization_option_id(customization_option, customization_option_items)
        {
          customization_option_id: customization_option[:id],
          customization_option_item_ids: customization_option_items.keys.sort,
          selected_customization_option_item_ids: customization_option_items.select { |k, a| a[:default_selected] }.keys.sort,
        }.to_json
      end

      def add_item(item)
        @item_ids ||= SortedSet.new
        return if @item_ids.include? item[:id]
        @item_ids.add item[:id]
        mapped_menu[:items][item[:id]] = item
      end

      def get_product_in_arabic(category_family_code, key)
        category = catalog_ar.select { |category| category["FamilyCode"] == category_family_code }&.first
        category["Products"][key]
      end
    end
  end
end
