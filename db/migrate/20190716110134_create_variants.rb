class CreateVariants < ActiveRecord::Migration[5.2]
  def change
    create_table :variants, id: :uuid do |t|
      t.references :product, foreign_key: true, type: :uuid
      t.string :sku
      t.float :price
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        ProductCatalog::Variant.create_translation_table! name: :string
      end

      dir.down do
        ProductCatalog::Variant.drop_translation_table!
      end
    end
  end
end
