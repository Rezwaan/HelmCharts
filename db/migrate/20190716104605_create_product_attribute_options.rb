class CreateProductAttributeOptions < ActiveRecord::Migration[5.2]
  def change
    create_table :product_attribute_options, id: :uuid do |t|
      t.references :product_attribute, foreign_key: true, type: :uuid
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        ProductCatalog::ProductAttributeOption.create_translation_table! name: :string
      end

      dir.down do
        ProductCatalog::ProductAttributeOption.drop_translation_table!
      end
    end
  end
end
