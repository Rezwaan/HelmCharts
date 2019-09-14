class AddCities < ActiveRecord::Migration[5.2]
  def change
    create_table :cities do |t|
      t.string :name, null: false, index: true
      t.multi_polygon :geom, geographic: true, srid: 4326

      t.timestamps
    end
  end
end
