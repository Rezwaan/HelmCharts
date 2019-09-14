class Admin::Presenters::Stores::Show
  def initialize(store)
    @store = store
  end

  def present(platform_stores: nil, working_time_rule: nil, catalog_assignment: nil)
    {
      "id": @store.id,
      "name": @store.name,
      "name_en": @store.name_en,
      "name_ar": @store.name_ar,
      "latitude": @store.latitude,
      "longitude": @store.longitude,
      "backend_id": @store.backend_id,
      "brand_id": @store.brand_id,
      "platform_stores": platform_stores&.map { |platform_store|
        {
          "platform_id": platform_store.platform_id,
          "status": platform_store.status,
        }
      },
      "catalog_assignment": catalog_assignment && {
        id: catalog_assignment.id,
        catalog_id: catalog_assignment.catalog_id,
      },
      working_time_rule: working_time_rule && Admin::Presenters::WorkingTimes::WorkingTimeRule.new(working_time_rule).present,
      "brand": Admin::Presenters::Brands::Show.new(@store.brand).present,
      "status": {
        "status": (@store.respond_to?(:status) ? @store.status[:status] : @store&.store_status&.status) || "temporary_busy",
        "reopen_at": @store.respond_to?(:status) ? @store.status[:reopen_at] : @store&.store_status&.reopen_at,
        "last_connected_at": @store.status[:last_connected_at],
        "connectivity_status": @store.status[:connectivity_status] || "offline",
      },
      "contact_number": @store.contact_number,
      "contact_name": @store.contact_name,
      "description": @store.description,
      "description_en": @store.description_en,
      "description_ar": @store.description_ar,
      "approved": @store.approved,
      "deleted_at": @store.deleted_at,
      "company_id": @store.company_id,
      "city": @store.city && {
        "id": @store.city[:id],
        "name": @store.city[:name],
      },
    }
  end
end
