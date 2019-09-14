class CreatePrototypeTable < ActiveRecord::Migration[5.2]
  def change
    create_table :prototypes, id: :uuid do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        ProductCatalog::Prototype.create_translation_table! name: :string
      end

      dir.down do
        ProductCatalog::Prototype.drop_translation_table!
      end
    end
  end
end
