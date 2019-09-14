class CreateIntegrationStores < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_stores, id: :uuid do |t|
      t.references :integration_host, foreign_key: true, type: :uuid
      t.string :external_reference
      t.jsonb :external_data
      t.references :store, foreign_key: true, index: {unique: true}

      t.timestamps
    end
  end
end
