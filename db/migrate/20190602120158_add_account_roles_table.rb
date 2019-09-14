class AddAccountRolesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :account_roles, id: :uuid do |t|
      t.integer :role
      t.references :role_resource, polymorphic: true, index: true
      t.references :account, index: true, type: :uuid
      t.timestamps null: false
    end
  end
end
