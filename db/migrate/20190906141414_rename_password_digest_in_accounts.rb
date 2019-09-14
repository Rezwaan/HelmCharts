class RenamePasswordDigestInAccounts < ActiveRecord::Migration[5.2]
  def change
    rename_column :accounts, :password_digest, :old_password_digest
  end
end
