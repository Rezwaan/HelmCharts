class Cities::CityService
  def city_by_lat_lng(lat:, long:)
    Cities::City.by_coordinates(lat, long).first
  end

  def create_dto(city)
    return unless city

    Cities::CityDTO.new({
      id: city.id,
      name: city.name,
    })
  end
end
