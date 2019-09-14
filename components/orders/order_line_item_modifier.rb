# == Schema Information
#
# Table name: order_line_item_modifiers
#
#  id                 :bigint           not null, primary key
#  item_reference     :string
#  quantity           :float
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  order_line_item_id :bigint
#
# Indexes
#
#  index_order_line_item_modifiers_on_order_line_item_id  (order_line_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_line_item_id => order_line_items.id)
#

class Orders::OrderLineItemModifier < ApplicationRecord
  belongs_to :order_line_item, class_name: Orders::OrderLineItem.name
  translates :group, touch: true, fallbacks_for_empty_translations: true
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name, :group]
end
