class AddConnectivityStatusIntoStoreStatuses < ActiveRecord::Migration[5.2]
  def change
    add_column :store_statuses, :connectivity_status, :integer, default: 2
  end
end
