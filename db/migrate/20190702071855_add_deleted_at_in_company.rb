class AddDeletedAtInCompany < ActiveRecord::Migration[5.2]
  def change
    add_column :companies, :deleted_at, :timestamp, default: nil
  end
end
