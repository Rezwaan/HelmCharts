require "json"

namespace :populate_cities do
  desc "Populate cities"
  task run: :environment do
    cities_url = Rails.application.secrets.cities[:end_point]

    puts "Fetching "
    response = HTTParty.get(
      cities_url,
    )

    cities_data = JSON.parse(response)["features"]

    cities_data.each do |feature|
      city = Cities::City.find_or_initialize_by(name: feature["properties"]["name"])

      if feature["geometry"]["coordinates"].present?
        points = {type: "MultiPolygon", coordinates: [feature["geometry"]["coordinates"]]}
        city.geom = RGeo::GeoJSON.decode(points.to_json, json_parser: :json)
      end

      city.save
    end

    associate_city_to_store
  end

  def city_by_lat_lng(latitude, longitude)
    Cities::City.by_coordinates(latitude, longitude).first
  end

  def associate_city_to_store
    Stores::Store.all.each do |store|
      if store.latitude.present? && store.longitude.present?
        puts "fetching city for store = #{store.name} with latitude = #{store.latitude} and longitude = #{store.longitude}"
        city = city_by_lat_lng(store.latitude, store.longitude)
        store.update_column(:city_id, city.id) if city
      end
    end
  end
end
