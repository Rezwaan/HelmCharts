class AddStoreItemAvailability < ActiveRecord::Migration[5.2]
  def change
    create_table :store_item_availabilities, id: :uuid do |t|
      t.references :store, index: true, null: false
      t.references :catalog, index: true, null: false, type: :uuid
      t.integer :item_id, index: true, null: false

      t.timestamps
    end

    add_index :store_item_availabilities, [:catalog_id, :store_id, :item_id], unique: true, name: "catalog_store_items_uniqness"
  end
end
