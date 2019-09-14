class AddDeletedAtToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :deleted_at, :timestamp, default: nil
  end
end
