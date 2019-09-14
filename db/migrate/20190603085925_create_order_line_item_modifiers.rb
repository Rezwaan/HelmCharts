class CreateOrderLineItemModifiers < ActiveRecord::Migration[5.2]
  def change
    create_table :order_line_item_modifiers do |t|
      t.references :order_line_item, foreign_key: true
      t.float :quantity

      t.timestamps
    end
  end
end
