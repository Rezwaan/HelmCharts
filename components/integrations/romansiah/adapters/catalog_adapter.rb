module Integrations
  module Romansiah
    module Adapters
      class CatalogAdapter
        attr_reader :categories, :products, :catalog

        def initialize(data)
          @categories, @products = data
          @catalog = {
            categories: {},
          }
        end

        def adapt
          build_categories
          build_products
          catalog
        end

        private

        def build_categories
          categories.each do |category|
            catalog[:categories][category["id"]] = category
            catalog[:categories][category["id"]][:products] = []
          end
        end

        def build_products
          products.each do |product|
            product["category_ids"].each do |id|
              next unless catalog[:categories][id]

              catalog[:categories][id][:products] << product
            end
          end
        end
      end
    end
  end
end
