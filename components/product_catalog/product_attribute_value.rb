# == Schema Information
#
# Table name: product_attribute_values
#
#  id                          :uuid             not null, primary key
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  product_attribute_option_id :uuid
#  variant_id                  :uuid
#
# Indexes
#
#  index_product_attribute_values_on_product_attribute_option_id  (product_attribute_option_id)
#  index_product_attribute_values_on_variant_id                   (variant_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_attribute_option_id => product_attribute_options.id)
#  fk_rails_...  (variant_id => variants.id)
#

class ProductCatalog::ProductAttributeValue < ApplicationRecord
  belongs_to :variant, class_name: ProductCatalog::Variant.name
  belongs_to :product_attribute_option, class_name: ProductCatalog::ProductAttributeOption.name

  def self.policy
    ProductCatalog::ProductAttributeValuePolicy
  end
end
