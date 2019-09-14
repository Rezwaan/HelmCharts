# This serializer is kept for compatability's sake until we are sure the
# Dome hacks are working well.
# TODO: Contact Kudu to fix these issues so we can remove this class and all its
# usages.
class Integrations::Sdm::Serializers::Hacks::Swyft::Kudu < Integrations::Sdm::Serializers::Hacks::BaseHacker
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
    return [] if categories.nil?

    categories = hide_invalid_categories(categories: categories)
    categories = hide_product_ids_meant_to_be_hidden_from_categories(
      categories: categories
    )

    override_category_names(categories: categories, locale: locale)
  end

  def apply_customization_option_hacks(customization_options)
    return [] if customization_options.nil?

    require_customization_options_that_are_mistakenly_not_required(
      customization_options: customization_options
    )
  end

  def apply_product_hacks(products:, integration_catalog_id:)
    return [] if products.nil?

    products = hide_products_meant_to_be_hidden(products: products)
    scrape_product_images(
      products: products,
      integration_catalog_id: integration_catalog_id
    )
  end

  private

  def hide_invalid_categories(categories:)
    categories.reject { |c| c[:id].in?(CATEGORY_IDS_TO_HIDE) }
  end

  def override_category_names(categories:, locale: :en)
    categories.map { |category|
      override = CATEGORIES_TO_OVERRIDE_NAMES_FOR[category[:id]]
      category[:name] = override[locale] if override && override[locale]

      category
    }
  end

  def require_customization_options_that_are_mistakenly_not_required(customization_options:)
    customization_options.map { |customization_option|
      if customization_option[:id].in?(CUSTOMIZATION_OPTIONS_MEANT_TO_BE_REQUIRED)
        customization_option[:max_selection] = 1
        customization_option[:min_selection] = 1
      end

      customization_option
    }
  end

  def hide_products_meant_to_be_hidden(products:)
    products.reject { |product| product[:id].in?(PRODUCT_IDS_TO_HIDE) }
  end

  def hide_product_ids_meant_to_be_hidden_from_categories(categories:)
    categories.map { |category|
      category[:product_ids] = category[:product_ids].reject { |product_id|
        product_id.in?(PRODUCT_IDS_TO_HIDE)
      }

      category
    }
  end

  def scrape_product_images(products:, integration_catalog_id:)
    threads = Rails.application.secrets.integrations[:number_of_threads_for_syncing]
    assets_api_client = Assets::Client.new

    Parallel.map(products, in_threads: threads) { |product|
      # Kudu has PNG images that are of higher quality, but not everything has them
      # so we went with the JPGs which almost everything appears to have instead.
      product_image_url = "https://beta.kudu.com.sa/img/menu/#{product[:id]}.jpg"
      upload_path = "integration_catalogs/#{integration_catalog_id}/images/products/#{product[:id]}/#{product[:id]}.jpg"

      # TODO: Also get sized variants using the assets client's `get_image_display_url`
      # for different image sizes once we have a clear standard on what size
      # to use.
      uploaded_image_url = assets_api_client.request_image_upload(
        image_url: product_image_url,
        upload_path: upload_path
      )

      next product unless uploaded_image_url

      product[:images] = [{
        "micro" => uploaded_image_url,
        "thumb" => uploaded_image_url,
        "small" => uploaded_image_url,
        "medium" => uploaded_image_url,
        "large" => uploaded_image_url,
      }]

      product
    }
  end
end
