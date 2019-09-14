class CreateStores < ActiveRecord::Migration[5.2]
  def up
    drop_table :stores
    create_table :stores do |t|
      t.references :brand, foreign_key: true, null: false
      t.string :backend_id, null: false
      t.decimal :latitude, precision: 10, scale: 8, null: false
      t.decimal :longitude, precision: 11, scale: 8, null: false

      t.timestamps
    end
    add_index :stores, [:brand_id, :backend_id], unique: true
  end

  def down
    remove_index :stores, [:brand_id, :backend_id]
    drop_table :stores
    create_table :stores do |t|
      t.string :name
      t.float :longitude
      t.float :latitude
      t.references :brand, index: true
      t.references :platform, index: true

      t.timestamps null: false
    end
  end
end
