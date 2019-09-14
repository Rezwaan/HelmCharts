class AllowNullForBackendIdInBrand < ActiveRecord::Migration[5.2]
  def up
    change_column :brands, :backend_id, :string, null: true
  end

  def down
    change_column :brands, :backend_id, :string
  end
end
