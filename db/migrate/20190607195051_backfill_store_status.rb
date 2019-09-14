class BackfillStoreStatus < ActiveRecord::Migration[5.2]
  def change
    Stores::Store.all.each do |store|
      Stores::StoreStatus.create(store_id: store.id, status: "ready")
    end
  end
end
