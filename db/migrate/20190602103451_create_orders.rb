class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :backend_id, null: false
      t.string :order_key, null: false
      t.integer :status, null: false, default: 1
      t.text :customer_notes
      t.decimal :amount, precision: 10, scale: 2
      t.decimal :discount, precision: 10, scale: 2
      t.decimal :delivery_fee, precision: 10, scale: 2
      t.decimal :collect_at_customer, precision: 10, scale: 2
      t.decimal :collect_at_pickup, precision: 10, scale: 2
      t.boolean :offer_applied, default: false
      t.string :coupon
      t.boolean :returnable, default: false
      t.string :return_code
      t.string :returned_status
      t.integer :payment_type, default: 1
      t.integer :order_type, default: 1
      t.references :customer, foreign_key: true, null: false
      t.references :customer_address, foreign_key: true, null: false
      t.references :store, foreign_key: true, null: false
      t.references :platform, foreign_key: true, null: false

      t.timestamps
    end
    add_index :orders, [:platform_id, :backend_id], unique: true
  end
end
