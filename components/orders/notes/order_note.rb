# == Schema Information
#
# Table name: order_notes
#
#  id              :uuid             not null, primary key
#  author_category :string
#  author_entity   :string
#  note            :text
#  note_type       :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  order_id        :bigint
#
# Indexes
#
#  index_order_notes_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#

class Orders::Notes::OrderNote < ApplicationRecord
  belongs_to :order, class_name: "Orders::Order"
  validates :order_id, presence: true
  enum note_type: {
    # Order Status
    received_successfully: 100,
    accepted_by_store: 101,
    out_for_delivery: 102,
    cancelled_by_store: 103,
    cancelled_by_platform: 104,
    cancelled_after_pickup_by_platform: 105,
    rejected_by_store: 106,
    delivered: 107,
    agent: 200,
  }
  scope :by_order_id, ->(order_id) { where(order_id: order_id) }
  scope :by_note_type, ->(note_type) { where(note_type: note_type) }
end
