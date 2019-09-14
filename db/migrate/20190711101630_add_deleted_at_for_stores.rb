class AddDeletedAtForStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :deleted_at, :datetime, nil: true
    add_index :stores, :deleted_at
  end
end
