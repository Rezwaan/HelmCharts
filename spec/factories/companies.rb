# == Schema Information
#
# Table name: companies
#
#  id                  :uuid             not null, primary key
#  deleted_at          :datetime
#  registration_number :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  country_id          :bigint
#
# Indexes
#
#  index_companies_on_country_id  (country_id)
#

FactoryBot.define do
  factory :company, class: Companies::Company do
    name_ar { Faker::Company.name }
    name_en { Faker::Company.name }
    registration_number { Faker::Company.duns_number }
  end
end
