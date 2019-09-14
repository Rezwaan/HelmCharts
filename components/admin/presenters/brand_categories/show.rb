class Admin::Presenters::BrandCategories::Show
  def initialize(brand_category)
    @brand_category = brand_category
  end

  def present
    {
      id: @brand_category.id,
      name_ar: @brand_category.name_ar,
      name_en: @brand_category.name_en,
      plural_name_ar: @brand_category.plural_name_ar,
      plural_name_en: @brand_category.plural_name_en,
      name: @brand_category.name,
      plural_name: @brand_category.plural_name,
      key: @brand_category.key,
    }
  end
end
