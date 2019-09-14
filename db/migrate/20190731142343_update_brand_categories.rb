class UpdateBrandCategories < ActiveRecord::Migration[5.2]
  def up
    Brands::Brand.where.not(brand_category_id: nil).each do |brand|
      Brands::BrandService.new.add_categories(id: brand.id, category_ids: [brand.brand_category_id])
    end
  end
end
