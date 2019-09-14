class AddColumnGeomToCountries < ActiveRecord::Migration[5.2]
  def change
    add_column :countries, :geom, :multi_polygon, geographic: true, srid: 4326
    add_column :countries, :currency_id, :integer
  end
end
