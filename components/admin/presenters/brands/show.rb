class Admin::Presenters::Brands::Show
  def initialize(brand)
    @brand = brand
  end

  def present(working_time_rule: nil)
    {
      "id": @brand.id,
      "name": @brand.name,
      "name_en": @brand.name_en,
      "name_ar": @brand.name_ar,
      "logo_url": @brand.logo_url,
      "cover_photo_url": @brand.cover_photo_url,
      "backend_id": @brand.backend_id,
      working_time_rule: working_time_rule && Admin::Presenters::WorkingTimes::WorkingTimeRule.new(working_time_rule).present,
      "brand_category": @brand.brand_category ? Admin::Presenters::BrandCategories::Show.new(@brand.brand_category).present : nil,
      "brand_categories": @brand.brand_categories.map { |brand_category| Admin::Presenters::BrandCategories::Show.new(brand_category).present },
      "approved": @brand.approved,
      "contracted": @brand.contracted,
      "country_id": @brand.country_id,
      "company_id": @brand.company_id,
    }
  end
end
