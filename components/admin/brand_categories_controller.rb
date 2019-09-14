class Admin::BrandCategoriesController < Admin::ApplicationController
  before_action :set_brand_category, only: [:update, :show]

  def index
    authorize(Brands::Categories::BrandCategory)

    brand_categories_dto = Brands::Categories::BrandCategoryService.new.filter(
      criteria: params.dig(:criteria) || {},
      page: @page,
      per_page: @per_page,
      sort_by: :created_at,
      sort_direction: "desc"
    )

    render json: {
      status: true,
      total_records: brand_categories_dto.total_count,
      total_pages: brand_categories_dto.total_pages,
      data: brand_categories_dto.map { |dto|
        Admin::Presenters::BrandCategories::Show.new(dto).present
      },
    }
  end

  def show
    authorize(Brands::Categories::BrandCategory)

    render json: Admin::Presenters::BrandCategories::Show.new(@brand_category).present
  end

  def create
    authorize(Brands::Categories::BrandCategory)

    brand_category = Brands::Categories::BrandCategoryService.new.create(attributes: brand_category_params)

    return render json: {error: brand_category.messages}, status: :unprocessable_entity if brand_category.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::BrandCategories::Show.new(brand_category).present
  end

  def update
    authorize(Brands::Categories::BrandCategory)

    brand_category = Brands::Categories::BrandCategoryService.new.update(
      id: @brand_category.id,
      attributes: brand_category_params,
    )

    return render json: {error: brand_category.messages}, status: :unprocessable_entity if brand_category.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::BrandCategories::Show.new(brand_category).present
  end

  private

  def brand_category_params
    attributes = [:key] + Brands::Categories::BrandCategory.globalize_attribute_names
    params.permit(attributes).to_h
  end

  def set_brand_category
    @brand_category = Brands::Categories::BrandCategoryService.new.fetch(id: params[:id])

    head :not_found if @brand_category.nil?
  end
end
