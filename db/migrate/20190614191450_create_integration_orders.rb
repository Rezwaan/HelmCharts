class CreateIntegrationOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_orders, id: :uuid do |t|
      t.references :integration_host, foreign_key: true, type: :uuid
      t.jsonb :external_data
      t.references :order, foreign_key: true
      t.integer :status
      t.string :external_reference

      t.timestamps
    end
  end
end
