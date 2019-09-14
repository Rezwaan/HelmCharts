class AddEncryptedPasswordInAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :encrypted_password, :string, null:false, default: ""
  end
end
