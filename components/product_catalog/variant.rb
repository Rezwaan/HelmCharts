# == Schema Information
#
# Table name: variants
#
#  id         :uuid             not null, primary key
#  price      :float
#  sku        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :uuid
#
# Indexes
#
#  index_variants_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#

class ProductCatalog::Variant < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  belongs_to :product, class_name: ProductCatalog::Product.name
  has_many :product_attribute_values, class_name: ProductCatalog::ProductAttributeValue.name
  has_many :product_attribute_options, class_name: ProductCatalog::ProductAttributeOption.name, through: :product_attribute_values, source: :product_attribute_option

  scope :by_name, ->(name) {
    joins(:translations)
      .where("variant_translations.name ILIKE ?", "%#{name}%").distinct
  }

  def self.policy
    ProductCatalog::VariantPolicy
  end
end
