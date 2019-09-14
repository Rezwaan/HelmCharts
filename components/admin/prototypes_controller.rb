class Admin::PrototypesController < Admin::ApplicationController
  before_action :set_prototype, only: [:show, :update]

  def index
    authorize(ProductCatalog::Prototype)

    prototypes_dto = ProductCatalog::PrototypeService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: prototypes_dto.total_count,
      total_pages: prototypes_dto.total_pages,
      data: prototypes_dto.map { |prototype_dto|
        Admin::Presenters::Prototypes::Show.new(prototype_dto).present
      },
    }
  end

  def show
    render json: Admin::Presenters::Prototypes::Show.new(@prototype).present
  end

  def create
    prototype = ProductCatalog::PrototypeService.new.create(attributes: prototype_params)

    if prototype.is_a?(ActiveModel::Errors)
      return render json: {error: prototype.messages}, status: :unprocessable_entity
    else
      return render json: Admin::Presenters::Prototypes::Show.new(prototype).present
    end
  end

  def update
    prototype = ProductCatalog::PrototypeService.new.update(prototype_id: @prototype.id, attributes: prototype_params)

    if prototype.is_a?(ActiveModel::Errors)
      return render json: {error: prototype.messages}, status: :unprocessable_entity
    else
      return render json: Admin::Presenters::Prototypes::Show.new(prototype).present
    end
  end

  private

  def set_prototype
    @prototype = ProductCatalog::PrototypeService.new.fetch(params[:id])
    return head :not_found if @prototype.nil?
  end

  def prototype_params
    attributes = [:id] + ProductCatalog::Prototype.globalize_attribute_names
    params.permit(attributes + [product_attribute_ids: []])
  end
end
