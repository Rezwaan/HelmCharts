class AddItemDetailInOrderLineItem < ActiveRecord::Migration[5.2]
  def change
    add_column :order_line_items, :item_detail, :jsonb
  end
end
