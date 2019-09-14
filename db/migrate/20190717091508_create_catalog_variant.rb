class CreateCatalogVariant < ActiveRecord::Migration[5.2]
  def up
    create_table :catalog_variants, id: :uuid do |t|
      t.references :catalog, index: true, type: :uuid
      t.string :catalog_key, null: false, index: true
      t.integer :priority, default: 0
      t.integer :start_from_minutes
      t.integer :end_at_minutes

      t.timestamps
    end

    start_from_minutes = 0
    end_at_minutes = 24 * 60

    Catalogs::Catalog.all.each do |catalog|
      catalog.catalog_variants.create(catalog_key: catalog.catalog_key, start_from_minutes: start_from_minutes, end_at_minutes: end_at_minutes)
    end
  end

  def down
    remove_index :catalog_variants, [:catalog_key]
    remove_index :catalog_variants, [:catalog_id]

    drop_table :catalog_variants
  end
end
