# == Schema Information
#
# Table name: manufacturers
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProductCatalog::Manufacturer < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  has_many :products, class_name: ProductCatalog::Product.name

  scope :by_name, ->(name) {
    joins(:translations)
      .where("manufacturer_translations.name ILIKE ?", "%#{name}%").distinct
  }

  def self.policy
    ProductCatalog::ManufacturerPolicy
  end
end
