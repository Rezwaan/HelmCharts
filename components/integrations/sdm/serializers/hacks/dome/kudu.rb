# TODO: Contact Kudu to fix these issues so we can remove this class and all its
# usages.
class Integrations::Sdm::Serializers::Hacks::Dome::Kudu < Integrations::Sdm::Serializers::Hacks::BaseHacker
  # SDM IDs of category that have issues from Kudu's side
  # This maps to a submenu ID on SDM
  CATEGORY_IDS_TO_HIDE = [
  ]

  # Products that Kudu should have marked as not visible but didn't and still
  # want to hide them.
  PRODUCT_IDS_TO_HIDE = [
    102068,
    102069,
    102070,
    102071,
    102072,
    102073,
  ]

  CATEGORIES_TO_OVERRIDE_NAMES_FOR = {
    8 => {
      en: "Breakfast - From 6 AM to 11 AM",
      ar: "الافطار - من ٦ الى ١١ صباحاً",
    },
  }

  # SDM IDs of customization options that are supposed to be required from
  # Kudu's side (meaning min amd max should be 1, but that's not the case)
  # This maps to a modifier group ID on SDM
  CUSTOMIZATION_OPTIONS_MEANT_TO_BE_REQUIRED = [
    19472, # What'is your favorite drink? (they typoed it like this, not me)
    16000, # What is your favorite drink?
    16002, # Hot drinks?

  ]

  def apply_category_hacks(categories:, locale: :en)
    return {} if categories.nil?

    categories = hide_invalid_categories(categories: categories)
    categories = hide_product_ids_meant_to_be_hidden_from_categories(
      categories: categories
    )

    override_category_names(categories: categories)
  end

  def apply_customization_option_hacks(customization_options)
    return {} if customization_options.nil?

    require_customization_options_that_are_mistakenly_not_required(
      customization_options: customization_options
    )
  end

  def apply_product_hacks(products:, integration_catalog_id:)
    return {} if products.nil?

    hide_products_meant_to_be_hidden(products: products)
  end

  private

  def hide_invalid_categories(categories:)
    categories.reject { |id, _| id.in?(CATEGORY_IDS_TO_HIDE) }
  end

  def override_category_names(categories:)
    CATEGORIES_TO_OVERRIDE_NAMES_FOR.each{ |id, override|
      next unless categories.key?(id)

      category = categories[id]
      category[:name] = override[:en] if override && override[:en]
      category[:name_ar] = override[:ar] if override && override[:ar]
    }

    categories
  end

  def require_customization_options_that_are_mistakenly_not_required(customization_options:)
    customization_options.map { |id, customization_option|
      if id.in?(CUSTOMIZATION_OPTIONS_MEANT_TO_BE_REQUIRED)
        customization_option[:max_selection] = 1
        customization_option[:min_selection] = 1
      end

      [id, customization_option]
    }.to_h
  end

  def hide_products_meant_to_be_hidden(products:)
    products.reject { |id, _| id.in?(PRODUCT_IDS_TO_HIDE) }
  end

  def hide_product_ids_meant_to_be_hidden_from_categories(categories:)
    categories.map { |id, category|
      category[:product_ids] = category[:product_ids].reject { |product_id, _|
        product_id.in?(PRODUCT_IDS_TO_HIDE)
      }

      [id, category]
    }.to_h
  end
end
