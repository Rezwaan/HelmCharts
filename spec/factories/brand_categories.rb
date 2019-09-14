# == Schema Information
#
# Table name: brand_categories
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_brand_categories_on_key  (key) UNIQUE
#

FactoryBot.define do
  factory :brand_category, class: Brands::Categories::BrandCategory do
    key { Faker::Team.unique.name }

    trait :named do
      name_ar { Faker::Coffee.blend_name }
      name_en { Faker::Coffee.blend_name }
      name { name_en }
      plural_name_ar { Faker::Coffee.blend_name }
      plural_name_en { Faker::Coffee.blend_name }
      plural_name { plural_name_en }
    end
  end
end
