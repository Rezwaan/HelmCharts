# == Schema Information
#
# Table name: order_line_items
#
#  id             :bigint           not null, primary key
#  discount       :decimal(10, 2)
#  image          :string
#  item_detail    :jsonb
#  item_reference :string
#  quantity       :float
#  total_price    :decimal(10, 2)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  backend_id     :string           not null
#  order_id       :bigint
#
# Indexes
#
#  index_order_line_items_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#

class Orders::OrderLineItem < ApplicationRecord
  belongs_to :order, class_name: Orders::Order.name
  has_many :order_line_item_modifiers, class_name: Orders::OrderLineItemModifier.name
  translates :name, touch: true, fallbacks_for_empty_translations: true
  translates :description, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name, :description]
  accepts_nested_attributes_for :order_line_item_modifiers, allow_destroy: true
end
