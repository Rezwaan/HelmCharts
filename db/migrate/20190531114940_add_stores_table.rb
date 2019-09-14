class AddStoresTable < ActiveRecord::Migration[5.2]
  def change
    create_table :stores do |t|
      t.string :name
      t.float :longitude
      t.float :latitude
      t.references :brand, index: true
      t.references :platform, index: true

      t.timestamps null: false
    end
  end
end
