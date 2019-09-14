class Admin::Presenters::Products::Show
  def initialize(product)
    @product = product
  end

  def present
    {
      id: @product.id,
      name_en: @product.name_en,
      name_ar: @product.name_ar,
      description_en: @product.description_en,
      description_ar: @product.description_ar,
      prototype: @product.prototype,
      manufacturer: @product.manufacturer,
      default_price: @product.default_price,
    }
  end
end
