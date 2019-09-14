class AddContactNameInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :contact_name, :string
  end
end
