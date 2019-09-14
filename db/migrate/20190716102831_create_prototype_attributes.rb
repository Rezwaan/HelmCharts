class CreatePrototypeAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :prototype_attributes, id: :uuid do |t|
      t.references :prototype, foreign_key: true, type: :uuid
      t.references :product_attribute, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
