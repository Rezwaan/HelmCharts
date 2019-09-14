class CreateBrandBrandCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :brand_brand_categories, id: :uuid do |t|
      t.references :brand, foreign_key: true
      t.references :brand_category, foreign_key: true

      t.timestamps
    end
    add_index :brand_brand_categories, [:brand_id, :brand_category_id], unique: true
  end
end
