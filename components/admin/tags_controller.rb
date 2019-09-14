class Admin::TagsController < Admin::ApplicationController
  before_action :set_tag, only: [:show, :update]

  def index
    authorize(Tags::Tag)

    tags_dto = Tags::TagService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: tags_dto.total_count,
      total_pages: tags_dto.total_pages,
      data: tags_dto.map { |tag_dto|
        Admin::Presenters::Tags::Show.new(tag_dto).present
      },
    }
  end

  def show
    authorize(@tag)

    render json: Admin::Presenters::Tags::Show.new(@tag).present
  end

  def create
    authorize(Tags::Tag)

    tag = Tags::TagService.new.create(attributes: tag_params)

    return render json: {error: tag.messages}, status: :unprocessable_entity if tag.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Tags::Show.new(tag).present
  end

  def update
    authorize(@tag)

    tag = Tags::TagService.new.update(tag_id: @tag.id, attributes: tag_params)

    return render json: {error: tag.messages}, status: :unprocessable_entity if tag.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Tags::Show.new(tag).present
  end

  private

  def set_tag
    @tag = Tags::TagService.new.fetch(params[:id])

    head :not_found if @tag.nil?
  end

  def tag_params
    attributes = [:id] + Tags::Tag.globalize_attribute_names
    params.permit(attributes)
  end
end
