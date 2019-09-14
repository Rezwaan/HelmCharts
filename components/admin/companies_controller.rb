class Admin::CompaniesController < Admin::ApplicationController
  before_action :set_company, only: [:show, :update, :destroy]

  def index
    authorize(Companies::Company)

    companies = Companies::CompanyService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    page_response(companies, record_mapper: lambda { |c| Admin::Presenters::Companies::Show.new(c).present })
  end

  def show
    authorize(@company)

    render json: Admin::Presenters::Companies::Show.new(Companies::CompanyService.new.fetch(@company.id)).present
  end

  def create
    authorize(Companies::Company)
    company = Companies::CompanyService.new.create(attributes: company_params)
    if company.blank? || company.is_a?(String)
      return render json: {error: company || "Company Not found"}, status: :unprocessable_entity
    else
      render json: Admin::Presenters::Companies::Show.new(company).present, status: :created
    end
  end

  def update
    authorize(@company)
    company = Companies::CompanyService.new.update(company_id: @company.id, attributes: company_params)
    if company.blank? || company.is_a?(String)
      return render json: {error: company || "Company Not found"}, status: :unprocessable_entity
    else
      render json: Admin::Presenters::Companies::Show.new(company).present
    end
  end

  def destroy
    authorize(@company)
    company = Companies::CompanyService.new.delete(id: @company.id)
    if company.blank? || company.is_a?(String)
      return render json: {error: company || "Company Not found"}, status: :unprocessable_entity
    else
      render json: Admin::Presenters::Companies::Show.new(company).present
    end
  end

  private

  def set_company
    @company = Companies::Company.not_deleted.find(params[:id])
  end

  def company_params
    attributes = [:registration_number, :country_id] + Companies::Company.globalize_attribute_names
    params.permit(attributes).to_h
  end
end
