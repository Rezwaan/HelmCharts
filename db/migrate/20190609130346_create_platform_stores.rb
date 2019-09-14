class CreatePlatformStores < ActiveRecord::Migration[5.2]
  def change
    create_table :platform_stores, id: :uuid do |t|
      t.references :store, foreign_key: true, index: true, null: false
      t.references :platform, foreign_key: true, index: true, null: false
      t.integer :status, default: 1, null: false
      t.timestamps
    end
    add_index :platform_stores, [:platform_id, :store_id], unique: true
  end
end
