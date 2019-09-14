class StoreItemAvailabilities::Workers::OutOfStockWorker
  include Sidekiq::Worker

  def perform(catalog_id, store_id, items_to_add, items_to_remove)
    if items_to_remove.present?
      StoreItemAvailabilities::StoreItemAvailabilityService.new.destroy(
        attributes: {
          item_id: items_to_remove,
          catalog_id: catalog_id,
          store_id: store_id,
        }
      )
    end

    if items_to_add.present?
      StoreItemAvailabilities::StoreItemAvailabilityService.new.create_availability_records(
        item_ids: items_to_add,
        catalog_id: catalog_id,
        store_id: store_id
      )
    end

    StoreItemAvailabilities::StoreItemAvailabilityService.new.publish_items(catalog_id: catalog_id, store_id: store_id)
  end
end
