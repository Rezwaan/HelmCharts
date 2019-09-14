class Admin::IntegrationCatalogsController < Admin::ApplicationController
  before_action :set_integration_catalog, only: [:show, :link_to_catalog, :sync_catalog]

  def index
    authorize(Integrations::IntegrationCatalog)

    integration_catalogs_dto = Integrations::IntegrationCatalogService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: integration_catalogs_dto.total_count,
      total_pages: integration_catalogs_dto.total_pages,
      data: integration_catalogs_dto.map { |integration_catalog_dto|
        Admin::Presenters::IntegrationCatalogs::Show.new(integration_catalog_dto).present
      },
    }
  end

  def show
    authorize(Integrations::IntegrationCatalog.find(params[:id]))

    render json: Admin::Presenters::IntegrationCatalogs::Show.new(@integration_catalog).present
  end

  def link_to_catalog
    authorize(Integrations::IntegrationCatalog.find(params[:id]))

    integration_catalog = Integrations::IntegrationCatalogService.new.update(
      integration_catalog_id: @integration_catalog.id,
      attributes: integration_catalog_params,
    )

    return render json: {error: integration_catalog.messages}, status: :unprocessable_entity if integration_catalog.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::IntegrationCatalogs::Show.new(integration_catalog).present
  end

  def sync_catalog
    authorize(Integrations::IntegrationCatalog.find(params[:id]))

    Integrations::Workers::CatalogSyncer.perform_async(@integration_catalog.id)

    # TODO: Find a way to notify user of actual sync status
    render json: {status: :ok}
  rescue => e
    render json: {error: e.message}, status: :bad_request
  end

  private

  def set_integration_catalog
    @integration_catalog = Integrations::IntegrationCatalogService.new.fetch(params[:id])

    head :not_found if @integration_catalog.nil?
  end

  def integration_catalog_params
    params.permit([:catalog_id]).to_h
  end
end
