class AddLastSyncedAtToIntegrationOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :integration_orders, :last_synced_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
  end
end
