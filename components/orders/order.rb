# == Schema Information
#
# Table name: orders
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(10, 2)
#  collect_at_customer :decimal(10, 2)
#  collect_at_pickup   :decimal(10, 2)
#  coupon              :string
#  customer_notes      :text
#  delivery_fee        :decimal(10, 2)
#  discount            :decimal(10, 2)
#  offer_applied       :boolean          default(FALSE)
#  order_key           :string           not null
#  order_type          :integer          default("food")
#  payment_type        :integer          default("cash")
#  return_code         :string
#  returnable          :boolean          default(FALSE)
#  returned_status     :string
#  status              :integer          default("received_successfully"), not null
#  transmission_medium :integer          default("reception"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  backend_id          :string           not null
#  currency_id         :bigint
#  customer_address_id :bigint           not null
#  customer_id         :bigint           not null
#  platform_id         :bigint           not null
#  reject_reason_id    :bigint
#  store_id            :bigint           not null
#
# Indexes
#
#  index_orders_on_currency_id                 (currency_id)
#  index_orders_on_customer_address_id         (customer_address_id)
#  index_orders_on_customer_id                 (customer_id)
#  index_orders_on_platform_id                 (platform_id)
#  index_orders_on_platform_id_and_backend_id  (platform_id,backend_id) UNIQUE
#  index_orders_on_reject_reason_id            (reject_reason_id)
#  index_orders_on_store_id                    (store_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_address_id => customer_addresses.id)
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (platform_id => platforms.id)
#  fk_rails_...  (store_id => stores.id)
#

class Orders::Order < ApplicationRecord
  include Common::Helpers::CurrencyHelper
  belongs_to :customer, class_name: "Customers::Customer"
  belongs_to :customer_address, class_name: "Customers::CustomerAddress"
  belongs_to :store, class_name: "Stores::Store"
  belongs_to :platform, class_name: "Platforms::Platform"
  has_many :order_line_items, class_name: Orders::OrderLineItem.name
  has_one :rush_delivery, class_name: RushDeliveries::RushDelivery.name
  accepts_nested_attributes_for :order_line_items, allow_destroy: true

  enum order_type: {
    food: 1,
    restaurant: 2,
    grocery: 3,
    pharmacy: 4,
  }

  enum payment_type: {
    cash: 1,
    wallet: 2,
    prepaid: 3,
  }

  enum transmission_medium: {
    reception: 1,
    integration: 2,
  }

  enum status: Orders::OrderStatus.key_ids
  enum delivery_type: DeliveryTypes::DeliveryType.key_ids

  def status_detail
    Orders::OrderStatus.find_by_key(status)
  end

  def state_key
    status_detail&.state_key
  end

  def state_id
    status_detail&.state_id
  end

  def state_name
    status_detail&.state_name
  end

  def state
    state_key
  end

  def phone_number
    "0#{customer.phone_number[4, 100]}"
  end

  def delivery_type_detail
    DeliveryTypes::DeliveryType.find_by_key(delivery_type)
  end
end
