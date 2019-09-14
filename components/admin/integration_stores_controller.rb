class Admin::IntegrationStoresController < Admin::ApplicationController
  before_action :set_integration_store, only: [:show, :link_to_store, :update, :sync_working_hours]

  def index
    authorize(Integrations::IntegrationStore)

    integration_stores_dto = Integrations::IntegrationStoreService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: integration_stores_dto.total_count,
      total_pages: integration_stores_dto.total_pages,
      data: integration_stores_dto.map { |integration_store_dto|
        Admin::Presenters::IntegrationStores::Show.new(integration_store_dto).present
      },
    }
  end

  def show
    authorize(Integrations::IntegrationStore.find(params[:id]))

    render json: Admin::Presenters::IntegrationStores::Show.new(@integration_store).present
  end

  def update
    authorize(Integrations::IntegrationStore.find(params[:id]))

    integration_store = Integrations::IntegrationStoreService.new.update(
      integration_store_id: @integration_store.id,
      attributes: integration_store_params,
    )

    return render json: {error: integration_store.messages}, status: :unprocessable_entity if integration_store.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::IntegrationStores::Show.new(integration_store).present
  end

  def link_to_store
    authorize(Integrations::IntegrationStore.find(params[:id]))

    integration_store = Integrations::IntegrationStoreService.new.update(
      integration_store_id: @integration_store.id,
      attributes: integration_store_params,
    )

    return render json: {error: integration_store.messages}, status: :unprocessable_entity if integration_store.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::IntegrationStores::Show.new(integration_store).present
  end

  private

  def set_integration_store
    @integration_store = Integrations::IntegrationStoreService.new.fetch(params[:id])

    head :not_found if @integration_store.nil?
  end

  def integration_store_params
    params.permit([:store_id, :enabled]).to_h
  end
end
