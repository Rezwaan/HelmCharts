class Admin::IntegrationHostsController < Admin::ApplicationController
  before_action :set_integration_host, only: [:show, :update, :sync_stores, :sync_catalog_list, :sync_stores_working_hours]

  def index
    authorize(Integrations::IntegrationHost)

    integration_hosts_dto = Integrations::IntegrationHostService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: integration_hosts_dto.total_count,
      total_pages: integration_hosts_dto.total_pages,
      data: integration_hosts_dto.map { |integration_host_dto|
        Admin::Presenters::IntegrationHosts::Show.new(integration_host_dto).present
      },
    }
  end

  def show
    authorize(Integrations::IntegrationHost.find(params[:id]))

    render json: Admin::Presenters::IntegrationHosts::Show.new(@integration_host).present
  end

  def create
    authorize(Integrations::IntegrationHost)

    integration_host = Integrations::IntegrationHostService.new.create(attributes: integration_host_params)

    return render json: {error: integration_host.messages}, status: :unprocessable_entity if integration_host.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::IntegrationHosts::Show.new(integration_host).present
  end

  def update
    authorize(Integrations::IntegrationHost.find(params[:id]))

    integration_host = Integrations::IntegrationHostService.new.update(
      integration_host_id: @integration_host.id,
      attributes: integration_host_params,
    )

    return render json: {error: integration_host.messages}, status: :unprocessable_entity if integration_host.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::IntegrationHosts::Show.new(integration_host).present
  end

  def integration_types
    authorize(Integrations::IntegrationHost)

    render json: Integrations::IntegrationHostService.new.integration_types
  end

  def sync_stores
    authorize(Integrations::IntegrationHost.find(params[:id]))

    render json: {status: integration_service&.sync_stores}
  rescue => e
    render json: {error: e.message}, status: :bad_request
  end

  def sync_catalog_list
    authorize(Integrations::IntegrationHost.find(params[:id]))

    render json: {status: integration_service&.sync_catalog_list}
  rescue => e
    render json: {error: e.message}, status: :bad_request
  end

  def sync_stores_working_hours
    authorize(Integrations::IntegrationHost.find(params[:id]))

    render json: {status: integration_service&.sync_working_hours}
  rescue => e
    render json: {error: e.message}, status: :bad_request
  end

  private

  def set_integration_host
    @integration_host = Integrations::IntegrationHostService.new.fetch(params[:id])

    head :not_found if @integration_host.nil?
  end

  def integration_service
    Integrations::IntegrationService.new.service(@integration_host)
  end

  def integration_host_params
    params.permit([:id, :name, :enabled, :integration_type, config: {}]).to_h
  end
end
