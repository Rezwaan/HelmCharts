# == Schema Information
#
# Table name: brand_brand_categories
#
#  id                :uuid             not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  brand_category_id :bigint
#  brand_id          :bigint
#
# Indexes
#
#  index_brand_brand_categories_on_brand_category_id               (brand_category_id)
#  index_brand_brand_categories_on_brand_id                        (brand_id)
#  index_brand_brand_categories_on_brand_id_and_brand_category_id  (brand_id,brand_category_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (brand_category_id => brand_categories.id)
#  fk_rails_...  (brand_id => brands.id)
#

class Brands::Categories::BrandBrandCategory < ApplicationRecord
  belongs_to :brand, class_name: "Brands::Brand"
  belongs_to :brand_category, class_name: "Brands::Categories::BrandCategory"
end
