class AddIntegrationFields < ActiveRecord::Migration[5.2]
  def change
    add_column :integration_hosts, :enabled, :boolean, null: false, default: true
    add_column :integration_stores, :enabled, :boolean, null: false, default: true
    add_column :orders, :transmission_medium, :integer, null: false, default: 1
    add_column :order_line_items, :item_reference, :string, null: true, default: nil
    add_column :order_line_item_modifiers, :item_reference, :string, null: true, default: nil
  end
end
