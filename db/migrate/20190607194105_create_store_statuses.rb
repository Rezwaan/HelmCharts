class CreateStoreStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :store_statuses, id: :uuid do |t|
      t.references :store, foreign_key: true, index: true, null: false
      t.integer :status, null: false, default: 1
      t.timestamp :reopen_at, :timestamp, default: nil, null: true
      t.timestamps
    end
  end
end
