class AddFieldsToCatalogVariant < ActiveRecord::Migration[5.2]
  def change
    add_column :catalog_variants, :name, :string
    add_column :catalog_variants, :deleted_at, :datetime
  end
end
