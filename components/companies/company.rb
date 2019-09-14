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

class Companies::Company < ApplicationRecord
  belongs_to :country, class_name: Countries::Country.name, optional: true
  has_many :brands, class_name: Brands::Brand.name
  has_many :stores, class_name: Stores::Store.name

  validates :name, presence: true, uniqueness: true
  # validates :registration_number, presence: true, uniqueness: true

  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :by_id, ->(id) { where(id: id) }
  scope :by_country, ->(country_id) { where(country_id: country_id) }
  scope :by_name, ->(name) {
    joins(:translations)
      .where("company_translations.name ILIKE ?", "%#{name}%").distinct
  }
  scope :by_country_name, ->(name) {
    joins(country: :translations)
      .where("country_translations.name ILIKE ?", "%#{name}%").distinct
  }

  def self.policy_class
    Companies::CompanyPolicy
  end
end
