module Integrations
  module Foodics
    module Adapters
      class CatalogAdapter
        attr_reader :categories, :products, :modifiers, :catalog

        def initialize(data)
          @categories, @products, @modifiers = data
          @catalog = {
            categories: {},
            modifiers: {},
          }
        end

        def adapt
          build_categories
          build_products
          build_modifiers
          catalog
        end

        private

        def build_categories
          categories.each do |category|
            catalog[:categories][category["hid"]] = category
            catalog[:categories][category["hid"]][:products] = []
          end
        end

        def build_products
          products.each do |product|
            catalog[:categories][product["category"]["hid"]][:products] << product
          end
        end

        def build_modifiers
          modifiers.each do |modifier|
            catalog[:modifiers][modifier["hid"]] = modifier
          end
        end
      end
    end
  end
end
