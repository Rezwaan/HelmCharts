class AddColumnDeliveryTypeToOrdersAndStores < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :delivery_type, :integer
    add_column :stores, :delivery_type, :integer
  end
end
