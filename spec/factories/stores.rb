# == Schema Information
#
# Table name: stores
#
#  id             :bigint           not null, primary key
#  contact_name   :string
#  contact_number :string
#  deleted_at     :datetime
#  flags          :integer          default(0)
#  latitude       :decimal(10, 8)   not null
#  longitude      :decimal(11, 8)   not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  backend_id     :string
#  brand_id       :bigint           not null
#  city_id        :bigint
#  company_id     :uuid
#
# Indexes
#
#  index_stores_on_brand_id    (brand_id)
#  index_stores_on_city_id     (city_id)
#  index_stores_on_company_id  (company_id)
#  index_stores_on_deleted_at  (deleted_at)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#

FactoryBot.define do
  factory :store, class: Stores::Store do
    name { Faker::Company.unique.name }
    contact_name { Faker::Name.name }
    contact_number { Faker::PhoneNumber.cell_phone }

    # flags

    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }

    association :brand, :with_category
  end
end
