# == Schema Information
#
# Table name: prototype_attributes
#
#  id                   :uuid             not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  product_attribute_id :uuid
#  prototype_id         :uuid
#
# Indexes
#
#  index_prototype_attributes_on_product_attribute_id  (product_attribute_id)
#  index_prototype_attributes_on_prototype_id          (prototype_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_attribute_id => product_attributes.id)
#  fk_rails_...  (prototype_id => prototypes.id)
#

class ProductCatalog::PrototypeAttribute < ApplicationRecord
  belongs_to :prototype, class_name: "ProductCatalog::Prototype"
  belongs_to :product_attribute, class_name: "ProductCatalog::ProductAttribute"
end
