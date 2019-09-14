class Admin::IntegrationCatalogOverridesController < Admin::ApplicationController
  before_action :set_override, only: [:update, :destroy]
  before_action :set_override_dto, only: [:show]

  def index
    authorize(Integrations::IntegrationCatalogOverride)

    integration_catalog_overrides_dto = Integrations::IntegrationCatalogOverrideService.filter(
      integration_catalog_id: params.dig(:integration_catalog_id),
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: integration_catalog_overrides_dto.total_count,
      total_pages: integration_catalog_overrides_dto.total_pages,
      data: integration_catalog_overrides_dto.map { |override|
        Admin::Presenters::IntegrationCatalogOverrides::Show.new(override).present
      },
    }
  end

  def show
    authorize(Integrations::IntegrationCatalogOverride)

    render json: Admin::Presenters::IntegrationCatalogOverrides::Show.new(@override).present
  end

  def create
    authorize(Integrations::IntegrationCatalogOverride)

    override = Integrations::IntegrationCatalogOverride.new(override_params)

    if override.save
      head :no_content
    else
      render json: override.errors.full_messages.as_json, status: :bad_request
    end
  end

  def update
    authorize(Integrations::IntegrationCatalogOverride)

    @override.update(override_params)

    if @override.save
      head :no_content
    else
      render json: @override.errors.full_messages.as_json, status: :bad_request
    end
  end

  def destroy
    authorize(Integrations::IntegrationCatalogOverride)

    @override.destroy
    head :no_content
  end

  private

  def set_override
    @override = Integrations::IntegrationCatalogOverride.find(params[:id])

    head :not_found if @override.nil?
  end

  def set_override_dto
    @override = Integrations::IntegrationCatalogOverrideService.fetch(params[:id])

    head :not_found if @override.nil?
  end

  def override_params
    params.require(:integration_catalog_override).permit(
      :integration_catalog_id,
      :item_type,
      :item_id,
      # This is necessary to allow dynamic properties
      properties: {},
    )
  end
end
