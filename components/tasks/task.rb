# == Schema Information
#
# Table name: tasks
#
#  id              :uuid             not null, primary key
#  expiry_at       :datetime
#  related_to_type :string
#  status          :integer          default("created"), not null
#  task_type       :integer          not null
#  timestamp       :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  related_to_id   :bigint
#  store_id        :bigint           not null
#
# Indexes
#
#  index_tasks_on_store_id  (store_id)
#
# Foreign Keys
#
#  fk_rails_...  (store_id => stores.id)
#

class Tasks::Task < ApplicationRecord
  belongs_to :store, class_name: "Stores::Store"

  enum task_type: {
    order_cancelation: 1,
  }

  enum status: {
    created: 1,
    completed: 2,
    expired: 3,
    canceled: 4,
  }

  scope :by_id, ->(id) { where(id: id) }
  scope :by_store, ->(store_ids) { where(store_id: store_ids) }
  scope :by_status, ->(statuses) { where(status: statuses) }
end
