module Integrations
  module Br
    module Serializers
      module Hacks
        class LotusBiscoff
          attr_reader :catalog, :customization_option_rules, :flavours

          def initialize
            @customization_option_rules = {}
            @flavours = {}
            @catalog = {
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

          def build_catalog(category_weight)
            build_flavours
            build_customization_option_rules
            build_categories(category_weight)
            build_products
            build_customization_options
            catalog
          end

          private

          def build_flavours
            flavours_data.each_with_index do |d, index|
              next if index.zero?

              flavour = {
                weight: d[0],
                id: d[1],
                name: d[2],
                name_ar: d[3],
              }

              flavour_id = flavour[:name]
              flavour_id = flavour[:id].to_i if flavour[:id]

              flavours[flavour_id.to_s] = {
                id: flavour_id,
                name: flavour[:name],
                name_ar: flavour[:name_ar],
                price: "0.0",
                weight: flavour[:weight].to_i,
                item_id: flavour_id,
              }

              add_item({
                id: flavour_id.to_s,
                reference_name: flavour_id.to_s,
                images: {},
                customization_option_ids: {},
                customization_ingredient_ids: {},
              })
            end
          end

          def build_customization_option_rules
            products_data.each_with_index do |d, index|
              remark = {
                product_id: d[1],
                rule: d[10],
              }

              next if index.zero?

              customization_option_rules[remark[:product_id].to_i.to_s] = get_customization_option_limits(remark[:rule])
            end
          end

          def build_categories(weight)
            products_data.each_with_index do |d, index|
              category = {
                product_id: d[1],
                name: d[4],
                name_ar: d[5],
              }

              next if index.zero? || category[:product_id].to_i == 0

              id = category[:name].to_s
              product_id = category[:product_id].to_i

              if catalog[:categories][id]
                catalog[:categories][id][:product_ids][product_id.to_s] = product_id
              else
                catalog[:categories][id] = {
                  id: id,
                  name: id,
                  name_ar: category[:name_ar],
                  weight: weight + 1,
                  product_ids: {"#{product_id}": product_id},
                }
              end
            end
          end

          def build_products
            products_data.each_with_index do |d, index|
              product = {
                id: d[1],
                reference_name: d[1],
                description: d[2],
                description_ar: d[3],
                name: d[2],
                name_ar: d[3],
                price: d[6],
                weight: d[0],
              }

              next if index.zero? || product[:id].to_i == 0

              [:id, :weight, :reference_name].each do |field|
                product[field] = product[field].to_i
              end

              [:price, :reference_name].each do |field|
                product[field] = product[field].to_s
              end

              product_id = product[:id].to_s
              product[:bundle_ids] = {"#{product_id}": product_id}
              catalog[:products][product_id] = product.except(:price).merge!(images: {})

              catalog[:bundles][product_id] = {
                id: product_id,
                name: product[:description],
                name_ar: product[:description_ar],
                reference_name: product_id,
                images: {},
                weight: index,
                description: product[:description],
                description_ar: product[:description_ar],
                item_bundle_ids: {"#{product_id}": product_id},
              }

              catalog[:items][product_id.to_s] = {
                id: product_id,
                reference_name: product_id,
                images: {},
                customization_option_ids: {},
                customization_ingredient_ids: {},
              }

              catalog[:item_bundles][product_id.to_s] = {
                id: product_id,
                name: product[:description],
                name_ar: product[:description_ar],
                description: product[:description],
                description_ar: product[:description_ar],
                price: product[:price].to_s,
                weight: index,
                item_id: product_id,
                bundle_id: product_id,
              }
            end
          end

          def build_customization_options
            catalog[:categories].each do |category_key, category|
              category[:product_ids].each_with_index do |(product_key, product_id), index|
                flavour_id = "Flavours-#{category_key}-#{product_key}".to_s
                rule = customization_option_rules[product_key.to_s]

                catalog[:customization_options][flavour_id] = {
                  id: flavour_id,
                  name: "Flavours",
                  name_ar: "نكهات",
                  reference_name: flavour_id,
                  images: {},
                  max_selection: rule[:max],
                  min_selection: rule[:min],
                  customization_option_item_ids: {},
                }

                if rule[:only]
                  build_single_customization_option_item(flavour_id, rule[:only][0], true)
                else
                  build_customization_option_items(flavour_id, rule[:excluded])
                end

                catalog[:items][product_id.to_s][:customization_option_ids] = {
                  "#{flavour_id}": {
                    id: flavour_id,
                    weight: index
                  }
                }
              end
            end
          end

          def build_customization_option_items(option_id, excluded)
            flavours.each do |key, value|
              next if excluded.include?(key)

              min = catalog[:customization_options][option_id]["min_selection"]
              max = catalog[:customization_options][option_id]["max_selection"]
              selected = (min == 1 && max == 1 && value[:weight] == 1)

              build_single_customization_option_item(option_id, key, selected)
            end
          end

          def build_single_customization_option_item(option_id, flavour_id, selected)
            flavour = flavours[flavour_id]
            catalog[:customization_option_items][flavour_id] = {
              id: flavour_id,
              name: flavour[:name],
              name_ar: flavour[:name_ar],
              price: "0.0",
              weight: flavour[:weight],
              default_selected: selected,
              customization_option_id: option_id,
              item_id: flavour_id,
            }
            catalog[:customization_options][option_id][:customization_option_item_ids][flavour_id] = flavour_id
          end

          def get_customization_option_limits(rule)
            items = ["226"]
            case rule
            when "You should choose exact 1 Flavor"
              return {min: 1, max: 1, excluded: items}
            when "You can choose 1 - 2 Flavors"
              return {min: 1, max: 2, excluded: items}
            when "Vanullla Flavor "
              return {min: 1, max: 1, only: items}
            when "Default Flavor - Cake"
              return {min: 1, max: 1, excluded: items}
            end
          end

          def add_item(item)
            catalog[:items][item[:id]] = item
          end

          def products_data
            data("products")
          end

          def flavours_data
            data("flavours")
          end

          def data(section)
            unless @data
              data_file = File.expand_path("data/lotus_biscoff.json", File.dirname(__FILE__))
              @data = JSON.parse(File.read(data_file))
            end

            @data[section]
          end
        end
      end
    end
  end
end
