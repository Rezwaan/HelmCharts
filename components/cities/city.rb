class Cities::City < ApplicationRecord
  scope :by_coordinates, ->(lat, lng) { where("ST_Intersects(cities.geom,ST_POINT(?, ?))", lng.to_f, lat.to_f) }
end
