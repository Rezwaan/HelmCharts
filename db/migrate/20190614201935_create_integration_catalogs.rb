class CreateIntegrationCatalogs < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_catalogs, id: :uuid do |t|
      t.references :integration_host, foreign_key: true, type: :uuid
      t.references :catalog, foreign_key: true, type: :uuid
      t.jsonb :external_data
      t.string :external_reference

      t.timestamps
    end
    add_index :integration_catalogs, [:integration_host_id, :external_reference], unique: true, name: "integration_catalogs_external_reference_uniqness"
  end
end
