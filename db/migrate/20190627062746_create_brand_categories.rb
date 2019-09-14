class CreateBrandCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :brand_categories do |t|
      t.string :key, null: false

      t.timestamps
    end
    add_index :brand_categories, :key, unique: true
  end
end
