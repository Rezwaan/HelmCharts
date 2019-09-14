class LiteApp::Api::V1::StoresController < LiteApp::Api::V1::ApplicationController
  before_action :authorize_store, only: [:ready, :temporary_busy]
  before_action :authorize_store_ids, only: [:summary_report]

  def index
    @stores = Stores::StoreService.new.filter(
      criteria: index_criteria,
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: @stores.total_count,
      total_pages: @stores.total_pages,
      data: @stores.map { |store| LiteApp::Presenter::Store.new(dto: store).present },
    }
  end

  def ready
    Stores::StoreStatusService.new.make_ready_by_store_id(params[:id])
    head :no_content
  end

  def temporary_busy
    duration_minutes = if params[:duration_minutes].present? && params[:duration_minutes].to_i < 24 * 60
      params[:duration_minutes].to_i
    end

    Stores::StoreStatusService.new.set_temporary_busy_by_store_id(
      params[:id],
      duration_minutes: duration_minutes,
      duration_type: params[:duration_type]
    )

    head :no_content
  end

  def summary_report
    criteria = params.dig(:criteria) || {type: "orders"}
    criteria[:store_ids] = store_ids_from_criteria(criteria)
    criteria[:store_ids] = account_store_ids unless criteria[:store_ids].present?

    report = Stores::SummaryReportService.new.summary_report(criteria: criteria)

    render json: report
  end

  private

  def authorize_store
    head :forbidden unless account_store_ids.include? params[:id].to_i
  end

  def index_criteria
    criteria = params.dig(:criteria) || {}
    criteria[:id] = account_store_ids
    criteria
  end
end
