class CreateCustomers < ActiveRecord::Migration[5.2]
  def change
    create_table :customers do |t|
      t.references :platform, null: false
      t.string :backend_id, null: false
      t.string :name
      t.string :phone_number

      t.timestamps
    end
    add_index :customers, [:platform_id, :backend_id], unique: true
  end
end
