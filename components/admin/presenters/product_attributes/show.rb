class Admin::Presenters::ProductAttributes::Show
  def initialize(product_attribute)
    @product_attribute = product_attribute
  end

  def present
    {
      id: @product_attribute.id,
      name_en: @product_attribute.name_en,
      name_ar: @product_attribute.name_ar,
      options: @product_attribute.options,
    }
  end
end
