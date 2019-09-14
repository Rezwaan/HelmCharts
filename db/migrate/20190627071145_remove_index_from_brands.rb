class RemoveIndexFromBrands < ActiveRecord::Migration[5.2]
  def up
    remove_index :stores, [:brand_id, :backend_id]
    remove_index :brands, [:platform_id, :backend_id]
    change_column_null(:brands, :platform_id, true)
  end

  def down
    change_column_null(:brands, :platform_id, false)
    add_index :brands, [:platform_id, :backend_id], unique: true
    add_index :stores, [:brand_id, :backend_id], unique: true
  end
end
