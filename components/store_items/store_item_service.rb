class StoreItems::StoreItemService
  def filter(criteria: {})
    catalog_assignment = Catalogs::CatalogAssignmentService.new.related_to(related_to_id: criteria[:store_id], related_to_type: "Stores::Store")

    if catalog_assignment
      catalog = catalog_assignment.catalog
      document_path = "#{collection_name}/#{catalog.id}"
      bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
      catalog_data = bot.fetch_document(path: document_path) || {}
      items = catalog_data.present? ? StoreItems::ItemsSerializer.new(catalog_data, lang: criteria[:language]).items : []

      items = mark_unavailable_items(store_id: criteria[:store_id], catalog_id: catalog.id, items: items)
      return {
        items: items,
        catalog_id: catalog.id,
      }
    else
      return {
        error: "Unable to find menu",
      }
    end
  end

  private

  def mark_unavailable_items(store_id:, catalog_id:, items: [])
    filters = {store_id: store_id, catalog_id: catalog_id}
    unavailable_items = StoreItemAvailabilities::StoreItemAvailabilityService.new.filter(criteria: filters)

    if items.present?
      unavailable_items.each do |unavailable_item|
        target_item = items.find { |item| item[:id] == unavailable_item[:item_id] }

        if target_item
          target_item[:is_available] = false
          target_item[:expiry_at] = unavailable_item[:expiry_at]
        end
      end
    end
    items.uniq { |item| [item[:id]] }
  end

  def collection_name
    "dome_lite.catalogs"
  end
end
