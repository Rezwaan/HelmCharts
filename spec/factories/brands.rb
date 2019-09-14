# == Schema Information
#
# Table name: brands
#
#  id                :bigint           not null, primary key
#  cover_photo_url   :string
#  flags             :integer          default(0), not null
#  logo_url          :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  backend_id        :string
#  brand_category_id :bigint
#  company_id        :uuid
#  country_id        :bigint
#  platform_id       :bigint
#
# Indexes
#
#  index_brands_on_brand_category_id  (brand_category_id)
#  index_brands_on_company_id         (company_id)
#  index_brands_on_country_id         (country_id)
#  index_brands_on_platform_id        (platform_id)
#
# Foreign Keys
#
#  fk_rails_...  (brand_category_id => brand_categories.id)
#  fk_rails_...  (country_id => countries.id)
#  fk_rails_...  (platform_id => platforms.id)
#

FactoryBot.define do
  factory :brand, class: Brands::Brand do
    name { Faker::Commerce.unique.product_name }
    logo_url { Faker::Internet.url }
    cover_photo_url { Faker::Internet.url }

    trait :with_category do
      association :brand_category
    end

    association :country
  end
end
