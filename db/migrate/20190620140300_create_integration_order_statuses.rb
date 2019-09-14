class CreateIntegrationOrderStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_order_statuses, id: :uuid do |t|
      t.references :integration_order, foreign_key: true, type: :uuid, index: true
      t.string :status
      t.jsonb :external_data, default: :nil
      t.timestamps
    end
  end
end
