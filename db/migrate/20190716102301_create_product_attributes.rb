class CreateProductAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :product_attributes, id: :uuid do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        ProductCatalog::ProductAttribute.create_translation_table! name: :string
      end

      dir.down do
        ProductCatalog::ProductAttribute.drop_translation_table!
      end
    end
  end
end
