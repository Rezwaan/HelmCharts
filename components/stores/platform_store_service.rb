class Stores::PlatformStoreService
  include Common::Helpers::PaginationHelper

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    platform_stores = Stores::PlatformStore.where(nil)
    platform_stores = platform_stores.by_id(criteria[:id]) if criteria[:id].present?
    platform_stores = platform_stores.by_store(criteria[:store_id]) if criteria[:store_id].present?
    platform_stores = platform_stores.by_platform(criteria[:platform_id]) if criteria[:platform_id].present?
    platform_stores = platform_stores.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: platform_stores, page: page, per_page: per_page) do |platform_store|
      create_dto(platform_store)
    end
  end

  def activate_pos(store_id:, platform_id:)
    store = Stores::Store.find store_id
    platform_store = Stores::PlatformStore.where(platform_id: platform_id, store_id: store_id).first_or_initialize
    platform_store.status = "active"
    if platform_store.save
      Stores::PubSub::Publish.new.update_store_pos_activation(data: {id: store.id, platform_id: platform_id, pos_status: "active"}, status: :pos_activated)
      return true
    else
      return false
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def deactivate_pos(store_id:, platform_id:)
    store = Stores::Store.find store_id
    platform_store = Stores::PlatformStore.where(platform_id: platform_id, store_id: store_id).first_or_initialize
    platform_store.status = "inactive"
    if platform_store.save
      Stores::PubSub::Publish.new.update_store_pos_activation(data: {id: store.id, platform_id: platform_id, pos_status: "inactive"}, status: :pos_deactivated)
      return true
    else
      return false
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def create_dto(platform_store)
    Stores::PlatformStoreDTO.new({
      platform_id: platform_store.platform_id,
      store_id: platform_store.store_id,
      status: platform_store.status,
    })
  end
end
