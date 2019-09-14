class LiteApp::Api::V1::StoreItemsController < LiteApp::Api::V1::ApplicationController
  before_action :authorized_store

  def list
    criteria = {store_id: params[:store_id], language: params[:language]}
    data = StoreItems::StoreItemService.new.filter(criteria: criteria)

    if data[:error]
      render json: data, status: :not_found
    else
      render json: data, status: :ok
    end
  end

  def update_item
    store_item = StoreItemAvailabilities::StoreItemAvailabilityService.new.update_items(attributes: store_item_params)

    if store_item.blank? || store_item.is_a?(ActiveModel::Errors)
      return render json: {error: store_item ? store_item.messages : "Unable to update"}, status: :unprocessable_entity
    end

    render json: LiteApp::Presenter::StoreItem.new(dto: store_item).present
  end

  def update_bulk_items
    store_items = StoreItemAvailabilities::StoreItemAvailabilityService.new.update_bulk_items(attributes: store_item_params)
    if store_items.blank? || store_items.is_a?(ActiveModel::Errors)
      return render json: {error: store_items.present? ? store_items.messages : "Unable to update"}, status: :unprocessable_entity
    end
    render json: store_items.map { |store_item| LiteApp::Presenter::StoreItem.new(dto: store_item).present }
  end

  def out_of_stock
    criteria = {store_id: params[:store_id], catalog_id: params[:catalog_id]}
    store_items = StoreItemAvailabilities::StoreItemAvailabilityService.new.filter(criteria: criteria)

    render json: {
      status: true,
      data: store_items.map { |store_item| LiteApp::Presenter::StoreItem.new(dto: store_item).present },
    }
  end

  private

  def store_item_params
    params.permit(:catalog_id, :store_id, :item_id, :status, expiry_at: [:duration_type, :duration_value], item_ids: [])
  end

  def authorized_store
    head :forbidden if params[:store_id].blank? || account_store_ids.map(&:to_s).exclude?(params[:store_id].to_s)
  end
end
