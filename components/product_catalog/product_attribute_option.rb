# == Schema Information
#
# Table name: product_attribute_options
#
#  id                   :uuid             not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  product_attribute_id :uuid
#
# Indexes
#
#  index_product_attribute_options_on_product_attribute_id  (product_attribute_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_attribute_id => product_attributes.id)
#

class ProductCatalog::ProductAttributeOption < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  belongs_to :product_attribute, class_name: ProductCatalog::ProductAttribute.name
  has_many :product_attribute_values, class_name: ProductCatalog::ProductAttributeValue.name

  scope :by_name, ->(name) {
    joins(:translations)
      .where("product_attribute_option_translations.name ILIKE ?", "%#{name}%").distinct
  }

  def self.policy
    ProductCatalog::ProductAttributeOptionPolicy
  end
end
