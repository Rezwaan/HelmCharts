class Stores::StoreStatusService
  def batch_set_ready(store_ids:)
    ready_status = Stores::StoreStatus.statuses[:ready]
    stores = Stores::Store.without_status(ready_status).where(id: store_ids)

    stores.each { |store| make_ready(store: store) }
  end

  def batch_set_temporary_busy(store_ids:)
    temporary_busy_status = Stores::StoreStatus.statuses[:temporary_busy]
    stores =
      Stores::Store.without_status(temporary_busy_status).where(id: store_ids)

    stores.each { |store| set_temporary_busy(store: store) }
  end

  def make_ready_by_store_id(store_id)
    make_ready(store: Stores::Store.find(store_id))
  end

  def set_temporary_busy_by_store_id(
    store_id, duration_minutes: nil, duration_type: nil
  )
    set_temporary_busy(
      store: Stores::Store.find(store_id),
      duration_minutes: duration_minutes,
      duration_type: duration_type
    )
  end

  def reopen_busy_stores(time: Time.now)
    Stores::StoreStatus.where(status: :temporary_busy).where.not(reopen_at: nil)
      .where("store_statuses.reopen_at <= ?", time).includes(store: :translations)
      .each { |store_status| make_ready(store: store_status.store) }
  end

  def update_last_connected_at(store_ids)
    store_ids.map { |store_id| set_redis(key: "stores.#{store_id}.last_connected_at", val: Time.now) }
  end

  def update_store_availability(time: Time.now)
    redis_keys = get_all_redis_keys(keys: "stores.*.last_connected_at")
    redis_keys.each do |key|
      redis_time = get_redis(key: key)
      time_difference_in_minutes = ((time - redis_time.to_time) / 60.0).round
      if time_difference_in_minutes > 10
        set_store_connectivity_status(store_id: key.split(".")[1], connectivity_status: "offline")
      else
        set_store_connectivity_status(store_id: key.split(".")[1], connectivity_status: "online")
      end
    end
  end

  def get_last_connected_at(store_id:)
    get_redis(key: "stores.#{store_id}.last_connected_at")
  end

  private

  def set_redis(key:, val:)
    $redis.with do |conn|
      conn.set(key, val)
    end
  end

  def get_all_redis_keys(keys:)
    $redis.with do |conn|
      conn.keys(keys)
    end
  end

  def get_redis(key:)
    $redis.with do |conn|
      conn.get(key)
    end
  end

  def set_store_connectivity_status(store_id:, connectivity_status:)
    store = Stores::Store.find(store_id)
    store_status = store.store_status
    return if connectivity_status == store_status.connectivity_status
    return if integrated_store(store)
    store_status.update(connectivity_status: connectivity_status)
    if store_status.status == "ready"
      if connectivity_status == "online"
        publish(store: store, status: "ready")
      else
        publish(store: store, status: "busy")
      end
    end
  end

  def publish(store:, status:)
    brand = Brands::BrandService.new.fetch(id: store.brand_id)
    Stores::PubSub::Publish.new.update_store_status(
      data:
      {
        id: store.id,
        platform_id: brand.platform_id,
        status: status,
      },
      status: status.to_sym
    )
  end

  def integrated_store(store)
    Integrations::IntegrationStore.where(store_id: store.id, enabled: true).any?
  end

  def make_ready(store:)
    return unless store

    brand = Brands::BrandService.new.fetch(id: store.brand_id)
    return unless brand

    store_status =
      Stores::StoreStatus.where(store_id: store.id).first_or_initialize
    store_status.status = :ready
    store_status.reopen_at = nil

    if store_status.save && store_status.saved_changes.present? && (store_status.connectivity_status == "online" || integrated_store(store))
      Stores::PubSub::Publish.new.update_store_status(
        data: {
          id: store.id,
          platform_id: brand.platform_id,
          status: "ready",
        },
        status: :ready
      )
    end
  end

  def set_temporary_busy(store:, duration_minutes: nil, duration_type: nil)
    return unless store

    brand = Brands::BrandService.new.fetch(id: store.brand_id)
    return unless brand

    reopen_at = nil

    # SET CLOSING BASED ON CURRENT DAY'S END TIME
    if duration_type.to_s != "end_of_day" && duration_minutes.to_i > 0
      reopen_at = Time.now + duration_minutes.to_i.minutes
    end

    store_status = Stores::StoreStatus.where(store_id: store.id).first_or_initialize
    store_status.status = :temporary_busy
    store_status.reopen_at = reopen_at

    if store_status.save && store_status.saved_changes.present? && store_status.connectivity_status == "online"
      Stores::PubSub::Publish.new.update_store_status(
        data: {
          id: store.id,
          platform_id: brand.platform_id,
          status: "busy",
        },
        status: :busy
      )
    end
  end
end
