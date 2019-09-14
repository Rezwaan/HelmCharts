class CreateIntegrationCatalogOverrides < ActiveRecord::Migration[5.2]
  def change
    create_table :integration_catalog_overrides, id: :uuid do |t|
      t.references :integration_catalog, foreign_key: true, type: :uuid
      t.string :item_id
      t.string :item_type
      t.jsonb :properties

      t.timestamps
    end

    add_index :integration_catalog_overrides, [:integration_catalog_id, :item_type, :item_id], unique: true, name: "integration_catalog_overrides_item_id_uniqueness"
  end
end
