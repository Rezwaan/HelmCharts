class StoreItemAvailabilities::StoreItemAvailabilityService
  ALLOWED_DURATION_TYPES = ["hours", "minutes", "days", "end_of_day"]

  def update_items(attributes: {})
    store_item = update_item(attributes)
    if attributes[:expiry_at].present?
      return unless attributes[:expiry_at][:duration_type].to_s.in?(ALLOWED_DURATION_TYPES)
      return unless attributes[:expiry_at][:duration_value].present?
      store_item.expiry_at = save_expiry_at(attributes[:expiry_at])
    end

    return if attributes[:status] == "enabled" && store_item.new_record?

    if attributes[:status] == "enabled" && store_item.persisted?
      store_item.destroy
      publish_items(catalog_id: attributes[:catalog_id], store_id: attributes[:store_id])
    elsif attributes[:status] == "disabled" && store_item.new_record?
      store_item = save_store_item(store_item: store_item, attributes: attributes)
    end

    store_item
  end

  def update_bulk_items(attributes: {})
    store_items = []
    attributes[:item_ids].each do |item_id|
      item_attribute = {catalog_id: attributes[:catalog_id], store_id: attributes[:store_id], status: attributes[:status], expiry_at: attributes[:expiry_at], item_id: item_id}
      store_item = update_item(item_attribute)
      if attributes[:expiry_at].present?
        next unless attributes[:expiry_at][:duration_type].to_s.in?(ALLOWED_DURATION_TYPES)
        next unless attributes[:expiry_at][:duration_value].present?
        store_item.expiry_at = save_expiry_at(attributes[:expiry_at])
      end
      next if attributes[:status] == "enabled" && store_item.new_record?
      if attributes[:status] == "enabled" && store_item.persisted?
        store_item.destroy
      elsif attributes[:status] == "disabled" && store_item.new_record?
        store_item = save_store_item(store_item: store_item, attributes: attributes, bulk_update: true)
      end
      return store_item if store_item.is_a?(ActiveModel::Errors)
      store_items << store_item
    end
    publish_items(catalog_id: attributes[:catalog_id], store_id: attributes[:store_id])
    store_items
  end

  def update_item(attributes)
    StoreItemAvailabilities::StoreItemAvailability.find_or_initialize_by(
      catalog_id: attributes[:catalog_id],
      store_id: attributes[:store_id],
      item_id: attributes[:item_id]
    )
  end

  def save_expiry_at(expiry_at)
    return Time.now.end_of_day if expiry_at[:duration_type] == "end_of_day"
    Time.now + expiry_at[:duration_value].to_i.send(expiry_at[:duration_type])
  end

  def save_store_item(store_item:, attributes: {}, bulk_update: false)
    if store_item.save
      publish_items(catalog_id: attributes[:catalog_id], store_id: attributes[:store_id]) unless bulk_update
      return create_dto(store_item)
    end

    store_item.errors
  end

  def mark_out_of_stock(store_id:, item_ids:, catalog_id: nil)
    if catalog_id.blank?
      catalog_assignment = Catalogs::CatalogAssignmentService.new.related_to(related_to_id: store_id, related_to_type: Stores::Store.name)
    end

    catalog_id ||= catalog_assignment&.catalog_id

    return unless catalog_id

    criteria = {catalog_id: catalog_id, store_id: store_id}
    store_items = filter(criteria: criteria)
    store_item_ids = store_items.pluck(:item_id)

    items_to_remove = store_item_ids - item_ids
    items_to_add = item_ids - store_item_ids

    if items_to_add.present? || items_to_remove.present?
      StoreItemAvailabilities::Workers::OutOfStockWorker.perform_async(catalog_id, store_id, items_to_add, items_to_remove)
    end
  end

  def filter(criteria: {})
    store_items = StoreItemAvailabilities::StoreItemAvailability.where(nil)
    store_items = store_items.by_store(criteria[:store_id]) if criteria[:store_id].present?
    store_items = store_items.by_catalog(criteria[:catalog_id]) if criteria[:catalog_id].present?

    store_items.map { |store_item| create_dto(store_item) }
  end

  def publish_items(catalog_id:, store_id:)
    store = Stores::StoreService.new.fetch_light(id: store_id)
    catalog = Catalogs::CatalogService.new.fetch(catalog_id)

    criteria = {catalog_id: catalog_id, store_id: store_id}
    data = filter(criteria: criteria)
    data = {catalog_id: catalog.id, store_primary_id: store.id, not_available_item_ids: data.pluck(:item_id)}
    publish_pubsub(data: data)
  end

  def destroy(attributes: {})
    StoreItemAvailabilities::StoreItemAvailability.where(attributes).destroy_all
  end

  def create_availability_records(item_ids:, catalog_id:, store_id:)
    item_ids.each do |item_id|
      store_item = StoreItemAvailabilities::StoreItemAvailability.find_or_initialize_by(
        catalog_id: catalog_id,
        store_id: store_id,
        item_id: item_id
      )
      store_item.save if store_item.new_record?
    end
  end

  def create_dto(store_item)
    return unless store_item
    StoreItemAvailabilities::StoreItemAvailabilityDTO.new(
      id: store_item.id,
      store_id: store_item.store_id,
      catalog_id: store_item.catalog_id,
      item_id: store_item.item_id,
      expiry_at: store_item.expiry_at&.strftime("%Y-%m-%d %H:%M")
    )
  end

  def remove_expired
    expired_store_items = StoreItemAvailabilities::StoreItemAvailability.where("expiry_at < ?", Time.now)
    grouped_data = expired_store_items.group("catalog_id", "store_id").select("catalog_id", "store_id").uniq
    publishable_data = grouped_data.map { |data| {catalog_id: data.catalog_id, store_id: data.store_id} }

    expired_store_items.in_batches(of: 10000).delete_all

    publishable_data.each do |data|
      publish_items(catalog_id: data[:catalog_id], store_id: data[:store_id])
    end
  end

  def by_catalog(catalog_id:)
    out_of_stock = StoreItemAvailabilities::StoreItemAvailability.by_catalog(catalog_id)
    out_of_stock.pluck(:item_id)
  end

  private

  def publish_pubsub(data: {})
    StoreItemAvailabilities::PubSub::Publish.new.publish_store_items(data: data, event: :out_of_stock_items, topic: :out_of_stock_items)
  end
end
