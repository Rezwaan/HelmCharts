class AddFcmTokenNotFoundInDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :fcm_token_not_found, :boolean, default: false
  end
end
