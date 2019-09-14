class CreateCatalogs < ActiveRecord::Migration[5.2]
  def change
    create_table :catalogs, id: :uuid do |t|
      t.string :name, null: false
      t.references :brand, foreign_key: true, index: true
      t.string :catalog_key, null: false
      t.timestamps
    end
  end
end
