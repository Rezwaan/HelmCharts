class Admin::ManufacturersController < Admin::ApplicationController
  before_action :set_manufacturer, only: [:show, :update]

  def index
    authorize(ProductCatalog::Manufacturer)

    manufacturers_dto = ProductCatalog::ManufacturerService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: manufacturers_dto.total_count,
      total_pages: manufacturers_dto.total_pages,
      data: manufacturers_dto.map { |manufacturer_dto|
        Admin::Presenters::Manufacturers::Show.new(manufacturer_dto).present
      },
    }
  end

  def show
    authorize(@manufacturer)

    render json: Admin::Presenters::Manufacturers::Show.new(@manufacturer).present
  end

  def create
    authorize(ProductCatalog::Manufacturer)

    manufacturer = ProductCatalog::ManufacturerService.new.create(attributes: manufacturer_params)

    return render json: {error: manufacturer.messages}, status: :unprocessable_entity if manufacturer.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Manufacturers::Show.new(manufacturer).present
  end

  def update
    authorize(@manufacturer)

    manufacturer = ProductCatalog::ManufacturerService.new.update(
      manufacturer_id: @manufacturer.id,
      attributes: manufacturer_params,
    )

    return render json: {error: manufacturer.messages}, status: :unprocessable_entity if manufacturer.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Manufacturers::Show.new(manufacturer).present
  end

  private

  def set_manufacturer
    @manufacturer = ProductCatalog::ManufacturerService.new.fetch(params[:id])

    head :not_found if @manufacturer.nil?
  end

  def manufacturer_params
    attributes = [:id] + ProductCatalog::Manufacturer.globalize_attribute_names
    params.permit(attributes)
  end
end
