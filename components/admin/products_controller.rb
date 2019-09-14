class Admin::ProductsController < Admin::ApplicationController
  before_action :set_product, only: [:show, :update]

  def index
    authorize(ProductCatalog::Product)

    products_dto = ProductCatalog::ProductService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: products_dto.total_count,
      total_pages: products_dto.total_pages,
      data: products_dto.map { |product_dto|
        Admin::Presenters::Products::Show.new(product_dto).present
      },
    }
  end

  def show
    authorize(@product)

    render json: Admin::Presenters::Products::Show.new(@product).present
  end

  def create
    authorize(ProductCatalog::Product)

    product = ProductCatalog::ProductService.new.create(attributes: product_params)

    return render json: {error: product.messages}, status: :unprocessable_entity if product.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Products::Show.new(product).present
  end

  def update
    authorize(@product)

    product = ProductCatalog::ProductService.new.update(product_id: @product.id, attributes: product_params)

    return render json: {error: product.messages}, status: :unprocessable_entity if product.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Products::Show.new(product).present
  end

  private

  def set_product
    @product = ProductCatalog::ProductService.new.fetch(params[:id])

    head :not_found if @product.nil?
  end

  def product_params
    attributes = [:id, :prototype_id, :manufacturer_id, :default_price]
    params.permit(attributes + ProductCatalog::Product.globalize_attribute_names)
  end
end
