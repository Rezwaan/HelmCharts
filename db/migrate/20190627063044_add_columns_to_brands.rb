class AddColumnsToBrands < ActiveRecord::Migration[5.2]
  def change
    add_column :brands, :flags, :integer, default: 0, null: false
    add_reference :brands, :brand_category, foreign_key: true
  end
end
