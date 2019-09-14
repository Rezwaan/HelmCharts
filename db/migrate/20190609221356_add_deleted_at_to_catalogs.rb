class AddDeletedAtToCatalogs < ActiveRecord::Migration[5.2]
  def change
    add_column :catalogs, :deleted_at, :timestamp, default: nil
  end
end
