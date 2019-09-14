# frozen_string_literal: true

class Admin::StoresController < Admin::ApplicationController
  before_action :set_store, only: [:show, :update, :destroy]
  before_action :set_deleted_store, only: :restore

  def index
    authorize(Stores::Store)

    stores_dto = Stores::StoreService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: stores_dto.total_count,
      total_pages: stores_dto.total_pages,
      data: stores_dto.map do |store_dto|
        Admin::Presenters::Stores::Show.new(store_dto).present(platform_stores: store_dto.platform_stores)
      end,
    }
  end

  def show
    authorize(@store)

    @platform_stores = Stores::PlatformStoreService.new.filter(criteria: {store_id: params[:id]})
    @working_time_rule = WorkingTimes::WorkingTimeRuleService.new.filter(
      criteria: {related_to_type: Stores::Store.name, related_to_id: params["id"]},
    ).first
    @catalog_assignment = Catalogs::CatalogAssignmentService.new.filter(
      criteria: {related_to_type: Stores::Store.name, related_to_id: params["id"]},
    ).first
    render json: Admin::Presenters::Stores::Show.new(Stores::StoreService.new.fetch(id: @store.id)).present(
      platform_stores: @platform_stores,
      working_time_rule: @working_time_rule,
      catalog_assignment: @catalog_assignment,
    )
  end

  def create
    authorize(Stores::Store)

    store = Stores::StoreService.new.create(attributes: store_params)

    if store.is_a?(ActiveModel::Errors)
      return render json: {error: store.messages}, status: :unprocessable_entity
    end

    render json: Admin::Presenters::Stores::Show.new(store).present
  end

  def update
    authorize(@store)

    store = Stores::StoreService.new.update(store: @store, attributes: store_params)

    if store.is_a?(ActiveModel::Errors)
      return render json: {error: store.messages}, status: :unprocessable_entity
    end

    render json: Admin::Presenters::Stores::Show.new(store).present
  end

  def destroy
    Stores::StoreService.new.soft_delete!(store: @store)

    head :ok
  end

  def restore
    Stores::StoreService.new.restore!(store: @store)

    head :ok
  end

  def activate_pos
    res = Stores::PlatformStoreService.new.activate_pos(platform_id: params[:platform_id], store_id: params[:id])

    return head :ok if res

    head :unprocessable_entity
  end

  def deactivate_pos
    res = Stores::PlatformStoreService.new.deactivate_pos(
      platform_id: params[:platform_id],
      store_id: params[:id],
    )

    return head :ok if res

    head :unprocessable_entity
  end

  def working_times
    working_time_rule = WorkingTimes::WorkingTimeRuleService.new.upsert(
      related_to_type: Stores::Store.name,
      related_to_id: params[:id],
      week_working_times: params[:week_working_time],
    )

    return render json: {error: working_time_rule.messages}, status: :unprocessable_entity if working_time_rule.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::WorkingTimes::WorkingTimeRule.new(working_time_rule).present
  end

  def delivery_types
    render json: DeliveryTypes::DeliveryType.all
  end

  private

  def store_params
    attributes = [:brand_id, :backend_id, :latitude, :longitude, :contact_number, :contact_name, :approved, :company_id, :delivery_type]
    params.permit(attributes + Stores::Store.globalize_attribute_names).to_h
  end

  def set_store
    @store = Stores::StoreService.new.find_by(attr: {id: params[:id]})

    head :not_found if @store.nil?
  end

  def set_deleted_store
    @store = Stores::StoreService.new.find_deleted_by(attr: {id: params[:id]})

    head :not_found if @store.nil?
  end
end
