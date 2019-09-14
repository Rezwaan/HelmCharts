module Integrations
  module Br
    module Adapters
      class CatalogAdapter
        attr_reader :categories, :flavours, :products, :toppings, :catalog

        def initialize(data)
          @categories, @flavours, @products, @toppings = data
          @catalog = {}
        end

        def adapt
          build_categories
          build_flavours
          build_products
          build_toppings
          catalog
        end

        private

        def build_categories
          get_entries_from_xml(categories).each do |entry|
            catalog[entry.children[0].text] = {
              category_code: entry.children[0].text,
              category_description: entry.children[1].text,
              arabic_category: entry.children[2].text,
              flavours: [],
              products: [],
              toppings: [],
            }
          end
        end

        def build_flavours
          get_entries_from_xml(flavours).each do |entry|
            catalog[entry.children[3].text][:flavours] << {
              flavour_code: entry.children[0].text,
              flavour_description: entry.children[1].text,
              arabic_description: entry.children[2].text,
              calories: entry.children[4].text,
            }
          end
        end

        def build_products
          get_entries_from_xml(products).each do |entry|
            category_id = entry.children[3].text
            price = entry.children[2].text
            next if skip_product?(category_id, price)

            no_topping = entry.children[10].text.blank? ? 0 : entry.children[10].text
            min_topping = entry.children[11].text.blank? ? 0 : entry.children[11].text

            catalog[category_id][:products] << {
              plu_code: entry.children[0].text,
              plu_description: entry.children[1].text,
              price: price,
              no_of_flavour: entry.children[4].text,
              product_and_description: entry.children[5].text,
              min_flavour: entry.children[6].text,
              plu_ar_description: entry.children[7].text,
              calories: entry.children[8].text,
              image_path: entry.children[9].text,
              no_of_topping: no_topping,
              min_topping: min_topping,
            }
          end
        end

        def build_toppings
          get_entries_from_xml(toppings).each do |entry|
            catalog[entry.children[3].text][:toppings] << {
              topping_code: entry.children[0].text,
              topping_description: entry.children[1].text,
              arabic_description: entry.children[2].text,
              calories: entry.children[4].text,
            }
          end
        end

        def skip_product?(category_id, price)
          category_id.blank? ||
            price.blank? ||
            catalog[category_id][:flavours].empty?
        end

        def get_entries_from_xml(xml)
          xml.xpath("//*[starts-with(local-name(), 'Entry')]")
        end
      end
    end
  end
end
