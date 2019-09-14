class Admin::Presenters::Prototypes::Show
  def initialize(prototype)
    @prototype = prototype
  end

  def present
    {
      id: @prototype.id,
      name_en: @prototype.name_en,
      name_ar: @prototype.name_ar,
      product_attribute_ids: @prototype.product_attribute_ids,
    }
  end
end
