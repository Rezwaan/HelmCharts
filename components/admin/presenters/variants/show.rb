class Admin::Presenters::Variants::Show
  def initialize(variant)
    @variant = variant
  end

  def present
    {
      id: @variant.id,
      name_en: @variant.name_en,
      name_ar: @variant.name_ar,
      sku: @variant.sku,
      price: @variant.price,
      product: @variant.product,
      product_attribute_option_ids: @variant.product_attribute_option_ids,
    }
  end
end
