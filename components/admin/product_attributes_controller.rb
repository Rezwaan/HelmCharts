class Admin::ProductAttributesController < Admin::ApplicationController
  before_action :set_product_attribute, only: [:show, :update]

  def index
    authorize(ProductCatalog::ProductAttribute)

    product_attributes_dto = ProductCatalog::ProductAttributeService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: product_attributes_dto.total_count,
      total_pages: product_attributes_dto.total_pages,
      data: product_attributes_dto.map { |product_attribute_dto|
        Admin::Presenters::ProductAttributes::Show.new(product_attribute_dto).present
      },
    }
  end

  def show
    authorize(@product_attribute)

    render json: Admin::Presenters::ProductAttributes::Show.new(@product_attribute).present
  end

  def create
    authorize(ProductCatalog::ProductAttribute)

    product_attribute = ProductCatalog::ProductAttributeService.new.create(attributes: product_attribute_params)

    return render json: {error: product_attribute.messages}, status: :unprocessable_entity if product_attribute.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::ProductAttributes::Show.new(product_attribute).present
  end

  def update
    authorize(@product_attribute)

    product_attribute = ProductCatalog::ProductAttributeService.new.update(
      product_attribute_id: @product_attribute.id,
      attributes: product_attribute_params,
    )

    return render json: {error: product_attribute.messages}, status: :unprocessable_entity if product_attribute.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::ProductAttributes::Show.new(product_attribute).present
  end

  private

  def set_product_attribute
    @product_attribute = ProductCatalog::ProductAttributeService.new.fetch(params[:id])

    head :not_found if @product_attribute.nil?
  end

  def product_attribute_params
    attributes = [:id] + ProductCatalog::ProductAttribute.globalize_attribute_names
    params.permit(attributes + options_params)
  end

  def options_params
    [
      options_attributes: [:id] + ProductCatalog::ProductAttributeOption.globalize_attribute_names,
    ]
  end
end
