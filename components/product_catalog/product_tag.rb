# == Schema Information
#
# Table name: product_tags
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :uuid
#  tag_id     :uuid
#
# Indexes
#
#  index_product_tags_on_product_id  (product_id)
#  index_product_tags_on_tag_id      (tag_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (tag_id => tags.id)
#

class ProductCatalog::ProductTag < ApplicationRecord
  belongs_to :product, class_name: ProductCatalog::Product.name
  belongs_to :tag, class_name: Tags::Tag.name

  def self.policy
    ProductCatalog::ProductTagPolicy
  end
end
