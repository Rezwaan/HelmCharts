# == Schema Information
#
# Table name: prototypes
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProductCatalog::Prototype < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  has_many :products, class_name: ProductCatalog::Product.name
  has_many :prototype_attributes, class_name: ProductCatalog::PrototypeAttribute.name
  has_many :product_attributes, class_name: ProductCatalog::ProductAttribute.name, through: :prototype_attributes, source: :product_attribute

  scope :by_name, ->(name) {
    joins(:translations)
      .where("prototype_translations.name ILIKE ?", "%#{name}%").distinct
  }

  def self.policy
    ProductCatalog::PrototypePolicy
  end
end
