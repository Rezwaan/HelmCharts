class CreateProductAttributeValues < ActiveRecord::Migration[5.2]
  def change
    create_table :product_attribute_values, id: :uuid do |t|
      t.references :product_attribute_option, foreign_key: true, type: :uuid
      t.references :variant, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
