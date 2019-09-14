class AddColumnsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :flags, :integer
    add_column :stores, :contact_number, :string
  end
end
