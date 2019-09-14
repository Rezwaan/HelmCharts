# == Schema Information
#
# Table name: catalogs
#
#  id          :uuid             not null, primary key
#  catalog_key :string           not null
#  deleted_at  :datetime
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  brand_id    :bigint
#
# Indexes
#
#  index_catalogs_on_brand_id  (brand_id)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#

FactoryBot.define do
  factory :catalog, class: Catalogs::Catalog do
    catalog_key { Faker::Commerce.product_name }
    name { Faker::Commerce.product_name }

    association :brand
  end
end
