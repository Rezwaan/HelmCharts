class LiteApp::Api::V1::OrdersController < LiteApp::Api::V1::ApplicationController
  include ActionController::MimeResponds
  before_action :set_order, only: [:show, :accept, :reject, :complete]
  before_action :authorize_store_ids, only: [:index]

  def index
    criteria = params[:criteria] || {}
    criteria[:store_ids] = store_ids_from_criteria(criteria)
    criteria[:store_ids] = account_store_ids unless criteria[:store_ids].present?

    orders = Orders::OrderService.new.filter(criteria: criteria, page: @page, per_page: @per_page)
    respond_to do |format|
      format.json do
        render json: {
          status: true,
          total_records: orders.total_count,
          total_pages: orders.total_pages,
          data: orders.map { |order| LiteApp::Presenter::Order.new(dto: order).present },
          rejection_reasons: RejectReasons::RejectReasonService.new.filter(per_page: nil),
        }
      end
      format.csv do
        data = LiteApp::Presenter::Order.columns.to_csv
        data += orders.map { |order| LiteApp::Presenter::Order.new(dto: order).to_a.to_csv }.join
        send_data data, filename: "orders-export.csv"
      end
    end
  end

  def active
    orders = Orders::OrderService.new.active(store_ids: account_store_ids)
    Stores::StoreStatusService.new.update_last_connected_at(account_store_ids) if account_store_ids.present?
    render json: orders.map { |order| LiteApp::Presenter::Order.new(dto: order).present }
  end

  def show
    render json: {
      data: LiteApp::Presenter::Order.new(dto: @order).present,
      rejection_reasons: RejectReasons::RejectReasonService.new.filter(per_page: nil),
    }
  end

  def accept
    begin
      @order = Orders::StatusUpdater.new(order: @order, author: author).accepted_by_store
    rescue Orders::Error::StatusChangedNotAllowed => _
      return render json: {error: "Status change not allowed"}, status: :unprocessable_entity
    end

    return render json: {error: "Cannot update order"}, status: :unprocessable_entity unless @order

    render json: {data: LiteApp::Presenter::Order.new(dto: @order).present}
  end

  def reject
    begin
      @order = Orders::StatusUpdater.new(order: @order, author: author).rejected_by_store(
        reject_reason_id: params[:reason_id],
      )
    rescue Orders::Error::StatusChangedNotAllowed => _
      return render json: {error: "Status change not allowed"}, status: :unprocessable_entity
    end

    return render json: {error: "Cannot update order"}, status: :unprocessable_entity unless @order

    render json: {data: LiteApp::Presenter::Order.new(dto: @order).present}
  end

  def complete
    begin
      @order = Orders::StatusUpdater.new(order: @order, author: author).out_for_delivery
    rescue Orders::Error::StatusChangedNotAllowed => _
      return render json: {error: "Status change not allowed"}, status: :unprocessable_entity
    end

    return render json: {error: "Cannot update order"}, status: :unprocessable_entity unless @order

    render json: {data: LiteApp::Presenter::Order.new(dto: @order).present}
  end

  def delivered
    begin
      @order = Orders::StatusUpdater.new(order: @order, author: author).delivered
    rescue Orders::Error::StatusChangedNotAllowed => _
      return render json: {error: "Status change not allowed"}, status: :unprocessable_entity
    end

    return render json: {error: "Cannot update order"}, status: :unprocessable_entity unless @order

    render json: {data: LiteApp::Presenter::Order.new(dto: @order).present}
  end

  def reject_reasons
    render json: {data: RejectReasons::RejectReasonService.new.filter(per_page: nil)}
  end

  def set_order
    criteria = {id: params[:id]}
    criteria[:store_id] = account_store_ids
    @order = Orders::OrderService.new.filter(criteria: criteria, per_page: 1, sort_direction: "asc", light: false).first

    render json: {error: "Order Not found"}, status: :unprocessable_entity unless @order
  end

  def author
    @author ||= Author.by_agent(entity: current_account)
  end
end
