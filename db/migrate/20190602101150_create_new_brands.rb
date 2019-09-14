class CreateNewBrands < ActiveRecord::Migration[5.2]
  def up
    drop_table :brands
    create_table :brands do |t|
      t.references :platform, foreign_key: true, null: false
      t.string :backend_id, null: false
      t.string :logo_url

      t.timestamps
    end
    add_index :brands, [:platform_id, :backend_id], unique: true
  end

  def down
    remove_index :brands, [:platform_id, :backend_id]
    drop_table :brands
    create_table :brands, id: :uuid do |t|
      t.string :backend_id, index: true
      t.string :name
    end
  end
end
