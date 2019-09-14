# == Schema Information
#
# Table name: platform_stores
#
#  id          :uuid             not null, primary key
#  status      :integer          default("inactive"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  platform_id :bigint           not null
#  store_id    :bigint           not null
#
# Indexes
#
#  index_platform_stores_on_platform_id               (platform_id)
#  index_platform_stores_on_platform_id_and_store_id  (platform_id,store_id) UNIQUE
#  index_platform_stores_on_store_id                  (store_id)
#
# Foreign Keys
#
#  fk_rails_...  (platform_id => platforms.id)
#  fk_rails_...  (store_id => stores.id)
#

class Stores::PlatformStore < ApplicationRecord
  belongs_to :platform, class_name: "Platforms::Platform"
  belongs_to :store, class_name: "Stores::Store"

  enum status: {
    inactive: 1,
    active: 2,
  }

  scope :by_id, ->(id) { where(id: id) }
  scope :by_store, ->(store_ids) { where(store_id: store_ids) }
  scope :by_platform, ->(platform_ids) { where(platform_id: platform_ids) }
end
