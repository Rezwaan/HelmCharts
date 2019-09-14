class StoreItems::ItemsSerializer
  def initialize(catalog_data, lang: "en")
    @catalog_data = catalog_data.with_indifferent_access
    @catalog_item_names = []
    @items_data = []
    @lang = lang
    @lang_postfix = ""
    if @lang != "en"
      @lang_postfix = "_#{@lang}"
    end
  end

  def items
    @catalog_data["categories"].each do |_, category|
      if category["product_ids"].present?
        @catalog_item_names << category[name_key]
        iterate_products(category["product_ids"])
        @catalog_item_names.pop
      end
    end

    @items_data
  end

  def iterate_products(product_ids)
    product_ids.map do |_, product_id|
      product = @catalog_data["products"][product_id.to_s]

      if product
        if product["bundle_ids"].present?
          @catalog_item_names << product[name_key]
          iterate_bundles(product["bundle_ids"])
          @catalog_item_names.pop
        end
      end
    end
  end


  def iterate_bundles(bundle_ids)
    bundle_ids.each do |_, bundle_id|
      bundle = @catalog_data["bundles"][bundle_id.to_s]
      if bundle
        if bundle["item_bundle_ids"].present?
          @catalog_item_names << bundle[name_key]
          iterate_item_bundles(bundle["item_bundle_ids"])
          @catalog_item_names.pop
        end
      end
    end
  end

  def iterate_item_bundles(item_bundle_ids)
    item_bundle_ids.each do |_, item_bundle_id|
      item_bundle = @catalog_data["item_bundles"][item_bundle_id.to_s]
      if item_bundle
        if item_bundle["item_id"].present?
          @catalog_item_names << item_bundle[name_key]
          @items_data << {
            category: @catalog_item_names.first,
            name: @catalog_item_names[1..-1].uniq.join(" - "),
            id: item_bundle["item_id"],
            is_available: true,
          }

          get_item(item_bundle["item_id"])

          @catalog_item_names.pop
        end
      end
    end
  end

  def get_item(item_id)
    item = @catalog_data["items"][item_id.to_s]

    if item
      if item["customization_option_ids"].present?
        iterate_customization_options(item["customization_option_ids"])
      else
        @items_data << {
          category: @catalog_item_names.first,
          name: @catalog_item_names[1..-1].uniq.join(" - "),
          id: item["id"],
          is_available: true,
        }
      end
    end
  end

  def iterate_customization_options(customization_option_ids)
    customization_option_ids.each do |_, customization_option_id|
      customization_option = @catalog_data["customization_options"][customization_option_id[:id].to_s]

      if customization_option
        @catalog_item_names << customization_option[name_key]
        if customization_option["customization_option_item_ids"].present?
          iterate_customization_options_items(customization_option["customization_option_item_ids"])
        end
        @catalog_item_names.pop
      end
    end
  end

  def iterate_customization_options_items(customization_option_item_ids)
    customization_option_item_ids.each do |_, customization_option_item_id|
      customization_option_item = @catalog_data["customization_option_items"][customization_option_item_id.to_s]

      if customization_option_item && customization_option_item["item_id"]
        @catalog_item_names << customization_option_item[name_key]
        @items_data << {
          category: @catalog_item_names.first,
          name: @catalog_item_names[1..-1].uniq.join(" - "),
          id: customization_option_item["item_id"],
          is_available: true,
        }
        @catalog_item_names.pop
      end
    end
  end

  def name_key
    "name#{@lang_postfix}"
  end
end
