class Admin::Presenters::ProductAttributeOptions::Show
  def initialize(product_attribute_option)
    @product_attribute_option = product_attribute_option
  end

  def present
    {
      id: @product_attribute_option.id,
      display_name: @product_attribute_option.display_name,
    }
  end
end
