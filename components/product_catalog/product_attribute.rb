# == Schema Information
#
# Table name: product_attributes
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProductCatalog::ProductAttribute < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  has_many :prototype_attributes, class_name: ProductCatalog::PrototypeAttribute.name
  has_many :prototypes, class_name: ProductCatalog::Prototype.name, through: :prototype_attributes
  has_many :options, class_name: ProductCatalog::ProductAttributeOption.name

  accepts_nested_attributes_for :options

  scope :by_name, ->(name) {
    joins(:translations)
      .where("product_attribute_translations.name ILIKE ?", "%#{name}%").distinct
  }

  def self.policy
    ProductCatalog::ProductAttributePolicy
  end
end
