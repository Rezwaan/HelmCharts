class AllowNullBackendIdInStore < ActiveRecord::Migration[5.2]
  def up
    change_column :stores, :backend_id, :string, null: true
  end

  def down
    change_column :stores, :backend_id, :string
  end
end
