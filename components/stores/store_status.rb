# == Schema Information
#
# Table name: store_statuses
#
#  id                  :uuid             not null, primary key
#  connectivity_status :integer          default("offline")
#  reopen_at           :datetime
#  status              :integer          default("ready"), not null
#  timestamp           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  store_id            :bigint           not null
#
# Indexes
#
#  index_store_statuses_on_store_id  (store_id)
#
# Foreign Keys
#
#  fk_rails_...  (store_id => stores.id)
#

class Stores::StoreStatus < ApplicationRecord
  belongs_to :store

  enum status: {
    ready: 1,
    temporary_busy: 2,
  }

  enum connectivity_status: {
    online: 1,
    offline: 2,
  }
end
