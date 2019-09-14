class Admin::VariantsController < Admin::ApplicationController
  before_action :set_variant, only: [:show, :update]

  def index
    authorize(ProductCatalog::Variant)

    variants_dto = ProductCatalog::VariantService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_direction: @sort_direction,
      sort_by: params[:sort_by],
    )

    render json: {
      status: true,
      total_records: variants_dto.total_count,
      total_pages: variants_dto.total_pages,
      data: variants_dto.map { |variant_dto|
        Admin::Presenters::Variants::Show.new(variant_dto).present
      },
    }
  end

  def show
    authorize(@variant)

    render json: Admin::Presenters::Variants::Show.new(@variant).present
  end

  def create
    authorize(ProductCatalog::Variant)

    variant = ProductCatalog::VariantService.new.create(attributes: variant_params)

    return render json: {error: variant.messages}, status: :unprocessable_entity if variant.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Variants::Show.new(variant).present
  end

  def update
    authorize(@variant)

    variant = ProductCatalog::VariantService.new.update(variant_id: @variant.id, attributes: variant_params)

    return render json: {error: variant.messages}, status: :unprocessable_entity if variant.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Variants::Show.new(variant).present
  end

  private

  def set_variant
    @variant = ProductCatalog::VariantService.new.fetch(params[:id])

    head :not_found if @variant.nil?
  end

  def variant_params
    attributes = [:id, :price, :sku, :product_id] + ProductCatalog::Variant.globalize_attribute_names
    params.permit(attributes + [product_attribute_option_ids: []])
  end
end
