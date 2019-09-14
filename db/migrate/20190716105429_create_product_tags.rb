class CreateProductTags < ActiveRecord::Migration[5.2]
  def change
    create_table :product_tags, id: :uuid do |t|
      t.references :product, foreign_key: true, type: :uuid
      t.references :tag, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
