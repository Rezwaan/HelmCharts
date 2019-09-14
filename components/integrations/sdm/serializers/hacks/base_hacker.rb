class Integrations::Sdm::Serializers::Hacks::BaseHacker
  def apply_category_hacks(categories:, locale: :en)
    categories
  end

  def apply_customization_option_hacks(customization_options)
    customization_options
  end

  def apply_product_hacks(products:, integration_catalog_id:)
    products
  end
end
