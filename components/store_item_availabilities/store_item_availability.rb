# == Schema Information
#
# Table name: store_item_availabilities
#
#  id         :uuid             not null, primary key
#  expiry_at  :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  catalog_id :uuid             not null
#  item_id    :integer          not null
#  store_id   :bigint           not null
#
# Indexes
#
#  catalog_store_items_uniqness                   (catalog_id,store_id,item_id) UNIQUE
#  index_store_item_availabilities_on_catalog_id  (catalog_id)
#  index_store_item_availabilities_on_item_id     (item_id)
#  index_store_item_availabilities_on_store_id    (store_id)
#

class StoreItemAvailabilities::StoreItemAvailability < ApplicationRecord
  belongs_to :store, class_name: "Stores::Store"
  belongs_to :catalog, class_name: "Catalogs::Catalog"

  scope :by_store, ->(store_id) { where(store_id: store_id) }
  scope :by_catalog, ->(catalog_id) { where(catalog_id: catalog_id) }

  validate :valid_expiry_at

  private

  def valid_expiry_at
    if expiry_at && expiry_at < Time.now
      errors.add(:expiry_at, "must be with a future expiry date")
    end
  end
end
