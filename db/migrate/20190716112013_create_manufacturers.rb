class CreateManufacturers < ActiveRecord::Migration[5.2]
  def change
    create_table :manufacturers, id: :uuid do |t|
      t.timestamps
    end

    add_reference :products, :manufacturer, foreign_key: true, type: :uuid

    reversible do |dir|
      dir.up do
        ProductCatalog::Manufacturer.create_translation_table! name: :string
      end

      dir.down do
        ProductCatalog::Manufacturer.drop_translation_table!
      end
    end
  end
end
