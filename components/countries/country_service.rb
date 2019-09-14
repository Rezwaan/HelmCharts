class Countries::CountryService
  include Common::Helpers::PaginationHelper

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    countries = Countries::Country.all
    countries = countries.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: countries, page: page, per_page: per_page) do |country|
      create_dto(country)
    end
  end

  def valid_country?(id:, lat:, lon:)
    Countries::Country.where(id: id).by_coordinates(lat, lon).any?
  end

  private

  def create_dto(country)
    Countries::CountryDTO.new({
      id: country.id,
      name: country.name,
      currency: country.currency,
      geom: country.geom,
    })
  end
end
