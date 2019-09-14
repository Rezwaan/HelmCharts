class CreateOrderLineItems < ActiveRecord::Migration[5.2]
  def change
    create_table :order_line_items do |t|
      t.references :order, foreign_key: true
      t.string :backend_id, null: false
      t.float :quantity
      t.decimal :total_price, precision: 10, scale: 2
      t.string :image
      t.decimal :discount, precision: 10, scale: 2

      t.timestamps
    end
  end
end
