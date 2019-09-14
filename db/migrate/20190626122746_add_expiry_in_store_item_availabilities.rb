class AddExpiryInStoreItemAvailabilities < ActiveRecord::Migration[5.2]
  def change
    add_column :store_item_availabilities, :expiry_at, :datetime
  end
end
