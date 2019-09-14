class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products, id: :uuid do |t|
      t.references :prototype, foreign_key: true, type: :uuid
      t.float :default_price
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        ProductCatalog::Product.create_translation_table! name: :string, description: :string
      end

      dir.down do
        ProductCatalog::Product.drop_translation_table!
      end
    end
  end
end
