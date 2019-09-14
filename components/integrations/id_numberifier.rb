module Integrations
  class IdNumberifier
    def catalog(catalog)
      res = {
        sets: catalog[:sets].map { |set| replace(set, %i[id]) },
        items: catalog[:items].map { |item|
                 replace(item, %i[id], %i[customization_option_ids customization_ingredient_ids])
               },
        bundles: catalog[:bundles].map { |bundle| replace(bundle, %i[id], %i[item_bundle_ids]) },
        products: catalog[:products].map { |product| replace(product, %i[id], %i[bundle_ids]) },
        item_sets: catalog[:item_sets].map { |item_set| replace(item_set, %i[id]) },
        categories: catalog[:categories].map { |category| replace(category, %i[id], %i[product_ids]) },
        bundle_sets: catalog[:bundle_sets].map { |bundle_set| replace(bundle_set, %i[id]) },
        item_bundles: catalog[:item_bundles].map { |item_bundle| replace(item_bundle, %i[id item_id bundle_id]) },
        customization_options: catalog[:customization_options].map { |customization_option| replace(customization_option, %i[id], %i[customization_option_item_ids]) },
        customization_ingredients: catalog[:customization_ingredients].map { |customization_ingredient| replace(customization_ingredient, %i[id]) },
        customization_option_items: catalog[:customization_option_items].map { |customization_option_item| replace(customization_option_item, %i[id customization_option_id item_id]) },
        customization_ingredient_items: catalog[:customization_ingredient_items].map { |customization_ingredient_item| replace(customization_ingredient_item, %i[id]) },
      }

      res
    end

    def firestore_catalog(catalog)
      result = {
        name: catalog[:name],
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

      catalog[:sets].each do |key, set|
        result[:sets][id_of(key)] = firestore_replace(set, %i[id])
      end

      catalog[:items].each do |key, item|
        id_of_key = id_of(key)
        result[:items][id_of_key] = firestore_replace(item, %i[id])
        result[:items][id_of_key][:customization_option_ids] = {}
        item[:customization_option_ids].each do |option_key, option|
          value = id_of(option_key)
          result[:items][id_of_key][:customization_option_ids][value] = {
            id: value,
            weight: option[:weight]
          }
        end

        result[:items][id_of_key][:customization_ingredient_ids] = {}
        item[:customization_ingredient_ids].each do |ingredient_key, ingredient|
          value = id_of(ingredient_key)
          result[:items][id_of_key][:customization_ingredient_ids][value] = value
        end
      end

      catalog[:bundles].each do |key, bundle|
        id_of_key = id_of(key)
        result[:bundles][id_of_key] = firestore_replace(bundle, %i[id])
        result[:bundles][id_of_key][:item_bundle_ids] = {}
        bundle[:item_bundle_ids].each do |item_bundle_key, item_bundle|
          value = id_of(item_bundle_key)
          result[:bundles][id_of_key][:item_bundle_ids][id_of(item_bundle_key)] = value
        end
      end

      catalog[:products].each do |key, product|
        id_of_key = id_of(key)
        result[:products][id_of_key] = firestore_replace(product, %i[id])
        result[:products][id_of_key][:bundle_ids] = {}
        product[:bundle_ids].each do |bundle_id_key, bundle_id|
          value = id_of(bundle_id_key)
          result[:products][id_of_key][:bundle_ids][value] = value
        end
      end

      catalog[:item_sets].each do |key, item_set|
        result[:item_sets][id_of(key)] = firestore_replace(item_set, %i[id])
      end

      catalog[:categories].each do |key, category|
        id_of_key = id_of(key)
        result[:categories][id_of_key] = firestore_replace(category, %i[id])
        result[:categories][id_of_key][:product_ids] = {}
        category[:product_ids].each do |product_id_key, product_id|
          value = id_of(product_id_key)
          result[:categories][id_of_key][:product_ids][value] = value
        end
      end

      catalog[:bundle_sets].each do |key, bundle_set|
        result[:bundle_sets][id_of(key)] = firestore_replace(bundle_set, %i[id])
      end

      catalog[:item_bundles].each do |key, item_bundle|
        result[:item_bundles][id_of(key)] = firestore_replace(item_bundle, %i[id item_id bundle_id])
      end

      catalog[:customization_options].each do |key, customization_option|
        id_of_key = id_of(key)
        result[:customization_options][id_of_key] = firestore_replace(customization_option, %i[id])
        result[:customization_options][id_of_key][:customization_option_item_ids] = {}
        customization_option[:customization_option_item_ids].each do |item_key, item|
          value = id_of(item_key)
          result[:customization_options][id_of_key][:customization_option_item_ids][value] = value
        end
      end

      catalog[:customization_ingredients].each do |key, customization_ingredient|
        result[:customization_ingredients][id_of(key)] = firestore_replace(customization_ingredient, %i[id])
      end

      catalog[:customization_option_items].each do |key, customization_option_item|
        result[:customization_option_items][id_of(key)] = firestore_replace(customization_option_item, %i[id customization_option_id item_id])
      end

      catalog[:customization_ingredient_items].each do |key, customization_ingredient_item|
        result[:customization_ingredient_items][id_of(key)] = firestore_replace(customization_ingredient_item, %i[id])
      end

      result
    end

    def order(order)
      order.line_items.each { |line_item| revert_line_item(line_item) }
      order
    end

    def id_of(id_str)
      id_mapping = IntegrationIdMapping.where(str: id_str).first
      id_mapping ||= IntegrationIdMapping.create(str: id_str)
      id_mapping.id
    end

    def str_of(id)
      id_mapping = IntegrationIdMapping.where(id: id).first
      id_mapping.str
    end

    def replace(object, fields, field_arrays = [])
      new_fields = {}
      fields.each do |field|
        new_fields[field] = id_of(object[field])
      end
      field_arrays.each do |field_array|
        new_fields[field_array] = object[field_array].map { |member| id_of(member) }
      end
      object.merge(new_fields)
    end

    def firestore_replace(object, fields, field_arrays = [])
      new_fields = {}
      fields.each do |field|
        new_fields[field] = id_of(object[field])
      end
      object.merge(new_fields)
    end

    def revert_line_item(line_item)
      line_item[:item_detail_reference] = {
        bundle_id: str_of(line_item[:item_detail]["bundle_id"]),
        product_id: str_of(line_item[:item_detail]["product_id"]),
        item_bundles: line_item[:item_detail]["item_bundles"].map { |item_bundle|
          {
            item_bundle_id: str_of(item_bundle["item_bundle_id"]),
            item: {
              item_id: str_of(item_bundle["item"]["item_id"]),
              customization_options: item_bundle["item"]["customization_options"].map { |customization_option|
                {
                  customization_option_id: str_of(customization_option["customization_option_id"]),
                  customization_option_item_ids: customization_option["customization_option_item_ids"].map { |customization_option_item_id|
                    str_of(customization_option_item_id)
                  },
                }
              },

              customization_ingredients: [],
            },
          }
        },
      }
    end
  end
end
