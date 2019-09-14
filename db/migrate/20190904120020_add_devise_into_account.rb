class AddDeviseIntoAccount < ActiveRecord::Migration[5.2]
  def up
    add_column :accounts, :email, :string
    add_column :accounts, :reset_password_token, :string
    add_column :accounts, :reset_password_sent_at, :datetime
    add_column :accounts, :remember_created_at, :datetime
    add_column :accounts, :sign_in_count, :integer, default: 0, null:false
    add_column :accounts, :last_sign_in_at, :datetime
    add_column :accounts, :current_sign_in_ip, :string
    add_column :accounts, :last_sign_in_ip, :string
    add_column :accounts, :confirmation_token, :string
    add_column :accounts, :confirmed_at, :datetime
    add_column :accounts, :confirmation_sent_at, :datetime
    add_column :accounts, :unconfirmed_email, :string
    add_column :accounts, :current_sign_in_at, :datetime

    add_index :accounts, :reset_password_token, unique: true
    add_index :accounts, :confirmation_token,   unique: true
  end

  def down
    remove_column :accounts, :email
    remove_column :accounts, :reset_password_token
    remove_column :accounts, :reset_password_sent_at
    remove_column :accounts, :remember_created_at
    remove_column :accounts, :sign_in_count
    remove_column :accounts, :last_sign_in_at
    remove_column :accounts, :current_sign_in_ip
    remove_column :accounts, :last_sign_in_ip
    remove_column :accounts, :confirmation_token
    remove_column :accounts, :confirmed_at
    remove_column :accounts, :confirmation_sent_at
    remove_column :accounts, :unconfirmed_email
    remove_column :accounts, :current_sign_in_at
  end
end
