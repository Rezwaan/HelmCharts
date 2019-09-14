class Catalogs::CatalogSerializer
  def initialize(catalog_data, lang: "en")
    @catalog_data = catalog_data.with_indifferent_access
    @lang = lang
    @lang_postfix = ""
    if @lang != "en"
      @lang_postfix = "_#{@lang}"
    end

    @enabled_product_ids = @catalog_data["products"].reject { |_, p| to_boolean(p["disabled"]) }.keys
    @enabled_bundle_ids = @catalog_data["bundles"].reject { |_, b| to_boolean(b["disabled"]) }.keys
    @enabled_customization_option_ids = @catalog_data["customization_options"].reject { |_, co| to_boolean(co["disabled"]) }.keys
    @enabled_customization_option_item_ids = @catalog_data["customization_option_items"].reject { |_, coi| to_boolean(coi["disabled"]) }.keys
  end

  def menu
    {
      categories: @catalog_data["categories"].map { |_, category|
        create_category(category)
      },
      products: @catalog_data["products"].map { |_, product|
        create_product(product)
      }.compact,
      bundles: @catalog_data["bundles"].map { |_, bundle|
        create_bundle(bundle, @catalog_data["item_bundles"])
      }.compact,
      items: @catalog_data["items"].map { |_, item|
        create_item(item)
      },
      item_bundles: @catalog_data["item_bundles"].map { |_, item_bundle|
        create_item_bundle(item_bundle)
      },
      customization_options: @catalog_data["customization_options"].map { |_, customization_option|
        create_customization_option(customization_option)
      }.compact,
      customization_option_items: @catalog_data["customization_option_items"].map { |_, customization_option_item|
        create_customization_option_item(customization_option_item)
      }.compact,
      sets: [],
      item_sets: [],
      bundle_sets: [],
      customization_ingredients: [],
      customization_ingredient_items: [],
    }
  end

  private

  def create_item(item)
    {
      "id": item["id"],
      "images": [],
      "customization_option_ids": filter_customization_option_ids(item.fetch("customization_option_ids", {})).keys.map(&:to_i),
      "customization_ingredient_ids": [],
    }
  end

  def filter_customization_option_ids(customization_option_ids)
    customization_option_ids.slice(*@enabled_customization_option_ids)
  end

  def create_bundle(bundle, item_bundles)
    return if to_boolean(bundle["disabled"])

    item_bundle = item_bundles.values.find { |ib| ib["bundle_id"] == bundle["id"] }

    {
      "id": bundle["id"],
      "name": (item_bundle && item_bundle[name_key]).to_s,
      "images": create_images(bundle["images"]),
      "weight": bundle["weight"].to_i,
      "description": (item_bundle && item_bundle[description_key]).to_s,
      "item_bundle_ids": bundle.fetch("item_bundle_ids", {}).keys.map(&:to_i),
    }
  end

  def create_product(product)
    return if to_boolean(product["disabled"])

    {
      "id": product["id"],
      "name": product[name_key],
      "images": create_images(product["images"]),
      "weight": product["weight"].to_i,
      "bundle_ids": filter_bundle_ids(product.fetch("bundle_ids", {})).keys.map(&:to_i),
      "description": product[description_key].to_s,
    }
  end

  def filter_bundle_ids(bundle_ids)
    bundle_ids.slice(*@enabled_bundle_ids)
  end

  def create_category(category)
    {
      "id": category["id"],
      "name": category[name_key],
      "weight": category["weight"].to_i,
      "product_ids": filter_product_ids(category.fetch("product_ids", {})).keys.map(&:to_i),
    }
  end

  def filter_product_ids(product_ids)
    product_ids.slice(*@enabled_product_ids)
  end

  def create_item_bundle(item_bundle)
    {
      "id": item_bundle["id"],
      "name": item_bundle[name_key],
      "price": item_bundle["price"].to_s,
      "weight": item_bundle["weight"].to_i,
      "item_id": item_bundle["item_id"],
      "bundle_id": item_bundle["bundle_id"],
    }
  end

  def create_customization_option(customization_option)
    return if to_boolean(customization_option["disabled"])

    {
      "id": customization_option["id"],
      "name": customization_option[name_key],

      # HACK: We don't really use customization_option.images, but since
      # Swyft iOS expects them to be an array of strings and Swyft Android
      # expects it to be an object, we'll send it as an empty array for now to
      # avoid breaking Swyft iOS.
      "images": [],

      "weight": customization_option["weight"].to_i,
      "max_selection": customization_option["max_selection"].to_i,
      "min_selection": customization_option["min_selection"].to_i,
      "customization_option_item_ids": customization_option.fetch("customization_option_item_ids", {}).keys.map(&:to_i),
    }
  end

  def filter_customization_option_item_ids(customization_option_item_ids)
    customization_option_item_ids.slice(*@enabled_customization_option_item_ids)
  end

  def create_customization_option_item(customization_option_item)
    return if to_boolean(customization_option_item["disabled"])

    mapped_customization_option_item = {
      "id": customization_option_item["id"],
      "name": customization_option_item[name_key],
      "price": customization_option_item["price"].to_s,
      "weight": customization_option_item["weight"].to_i,
      "default_selected": to_boolean(customization_option_item["default_selected"]),
      # TODO: validate that `customization_option_id` is valid
      "customization_option_id": customization_option_item["customization_option_id"],
    }

    if customization_option_item["item_id"].present?
      mapped_customization_option_item[:item_id] = customization_option_item["item_id"]
    end
    mapped_customization_option_item
  end

  def name_key
    "name#{@lang_postfix}"
  end

  def description_key
    "description#{@lang_postfix}"
  end

  def create_images(images)
    return Array(images) unless images.is_a?(Hash)
    images.values.map { |image_url| create_image_object(image_url) }
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

  def to_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
