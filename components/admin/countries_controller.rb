class Admin::CountriesController < Admin::ApplicationController
  def index
    authorize(Countries::Country)

    countries_dto = Countries::CountryService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: countries_dto.total_count,
      total_pages: countries_dto.total_pages,
      data: countries_dto.map { |country_dto|
        Admin::Presenters::Countries::Show.new(country_dto).present
      },
    }
  end
end
