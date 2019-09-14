# == Schema Information
#
# Table name: rush_deliveries
#
#  id                   :uuid             not null, primary key
#  drop_off_description :text             not null
#  drop_off_latitude    :decimal(10, 6)   not null
#  drop_off_longitude   :decimal(10, 6)   not null
#  pick_up_latitude     :decimal(10, 6)   not null
#  pick_up_longitude    :decimal(10, 6)   not null
#  status               :enum             default("unassigned")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  order_id             :bigint           not null
#
# Indexes
#
#  index_rush_deliveries_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#

class RushDeliveries::RushDelivery < ApplicationRecord
  belongs_to :order, class_name: Orders::Order.name, optional: true
  has_one :store, through: :order

  validates :order_id, :drop_off_latitude, :drop_off_longitude, :pick_up_latitude, :drop_off_longitude,
            presence: true, allow_blank: false

  enum status: RushDeliveries::RushDeliveryStatus.enum_hash

  def status
    @status ||= RushDeliveries::RushDeliveryStatus.new(read_attribute(:status))
  end
end
