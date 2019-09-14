class CreateCustomerAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :customer_addresses do |t|
      t.string :backend_id, null: false
      t.references :customer, foreign_key: true, null: false
      t.decimal :latitude, precision: 10, scale: 8, null: false
      t.decimal :longitude, precision: 11, scale: 8, null: false
      t.timestamps
    end
    add_index :customer_addresses, [:customer_id, :backend_id], unique: true
  end
end
