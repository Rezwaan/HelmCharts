class Admin::BrandsController < Admin::ApplicationController
  before_action :set_brand, only: [:show, :update, :working_times]

  def index
    authorize(Brands::Brand)

    brands_dto = Brands::BrandService.new.filter(
      criteria: params.dig(:criteria) || {},
      page: @page,
      per_page: @per_page,
      sort_by: :created_at,
      sort_direction: "desc",
    )

    render json: {
      status: true,
      total_records: brands_dto.total_count,
      total_pages: brands_dto.total_pages,
      data: brands_dto.map { |brand| Admin::Presenters::Brands::Show.new(brand).present },
    }
  end

  def show
    authorize(@brand)

    @working_time_rule = WorkingTimes::WorkingTimeRuleService.new.filter(criteria: {
      related_to_type: Brands::Brand.name,
      related_to_id: params["id"],
    }).first
    brand = Brands::BrandService.new.fetch(id: @brand.id)
    render json: Admin::Presenters::Brands::Show.new(brand).present(working_time_rule: @working_time_rule)
  end

  def create
    authorize(Brands::Brand)

    brand = Brands::BrandService.new.create(attributes: brand_params, category_ids: category_ids)

    return render json: brand.messages, status: :unprocessable_entity if brand.is_a?(ActiveModel::Errors)
    render json: Admin::Presenters::Brands::Show.new(brand).present
  end

  def update
    authorize(@brand)

    brand = Brands::BrandService.new.update(brand: @brand, attributes: brand_params, category_ids: category_ids)

    return render json: brand.messages, status: :unprocessable_entity if brand.is_a?(ActiveModel::Errors)
    render json: Admin::Presenters::Brands::Show.new(brand).present
  end

  def working_times
    authorize(@brand)

    working_time_rule = WorkingTimes::WorkingTimeRuleService.new.upsert(
      related_to_type: Brands::Brand.name,
      related_to_id: params[:id],
      week_working_times: params[:week_working_time],
    )

    return render json: working_time_rule.messages, status: :unprocessable_entity if working_time_rule.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::WorkingTimes::WorkingTimeRule.new(working_time_rule).present
  end

  private

  def brand_params
    attributes = [:platform_id, :backend_id, :logo_url, :cover_photo_url, :approved, :contracted, :country_id, :company_id]
    params.permit(attributes + Brands::Brand.globalize_attribute_names).to_h
  end

  def set_brand
    @brand = Brands::Brand.find_by(id: params[:id])

    head :not_found if @brand.nil?
  end

  def category_ids
    brand_category_ids = Array(params[:brand_category_ids]) if params[:brand_category_ids].present?
    brand_category_ids = Array(params[:brand_category_id]) if brand_category_ids.blank?
    brand_category_ids.present? || !params[:brand_category_ids].nil? ? brand_category_ids : nil
  end
end
