class Stores::StoreService
  include Common::Helpers::PaginationHelper

  def find_or_create(brand_id:, attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    begin
      store = Stores::Store.where(brand_id: brand_id, backend_id: attributes[:backend_id]).first_or_initialize
      store.name_en = attributes[:name_en] if attributes[:name_en].present?
      store.name_ar = attributes[:name_ar] if attributes[:name_ar].present?
      store.latitude = attributes[:address][:latitude] if attributes.dig(:address, :latitude).present?
      store.longitude = attributes[:address][:longitude] if attributes.dig(:address, :longitude).present?
      store.company_id = attributes[:company_id] if attributes[:company_id].present?
      if store.new_record?
        store.build_store_status(status: "temporary_busy")
      end
      return create_dto(store) if store.save
      store.errors
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def create(attributes:)
    store = Stores::Store.new(attributes)
    store.build_store_status(status: "temporary_busy")
    store.city_id = city_for_store(store: store)

    begin
      if store.save
        data = create_dto(store)
        publish_pubsub(data: data, event: :created_store, topic: :created_store)
        return data
      end
    rescue ActiveRecord::RecordNotUnique
      store.errors.add(:unique, message: "backend id must be unique")
    end

    store.errors
  end

  def update(store:, attributes:)
    begin
      store.assign_attributes(attributes)
      store.city_id = city_for_store(store: store)

      if store.save
        data = create_dto(store)
        publish_pubsub(data: data, event: :updated_store, topic: :updated_store)
        return data
      end
    rescue ActiveRecord::RecordNotUnique
      store.errors.add(:unique, message: "backend id must be unique")
    end

    store.errors
  end

  def city_for_store(store:)
    city = Cities::CityService.new.city_by_lat_lng(lat: store.latitude, long: store.longitude)
    return unless city

    city.id
  end

  def soft_delete!(store:)
    store.soft_delete!

    if store.deleted?
      Catalogs::CatalogAssignmentService.new.destroy_by_store(store_id: store.id)
      publish_pubsub(data: create_dto(store), event: :updated_store, topic: :updated_store)
    end
  end

  def restore!(store:)
    store.restore!
    publish_pubsub(data: create_dto(store), event: :updated_store, topic: :updated_store)
  end

  def fetch_by_store(store:)
    store_obj = Stores::Store.find_by(id: store[:id]) if store[:id].present?
    create_dto(store_obj)
  end

  def fetch(id:)
    store = Stores::Store.find_by(id: id)
    create_dto(store)
  end

  def fetch_light(id:)
    store = Stores::Store.find_by(id: id)
    create_light_dto(store)
  end

  def find_deleted_by(attr: {})
    Stores::Store.by_soft_deleted.find_by(attr)
  end

  def find_by(attr: {})
    Stores::Store.find_by(attr)
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    stores = apply_scopes(criteria: criteria)
      .includes(:store_status, :translations, brand: [:translations, brand_category: [:translations]])
    stores = stores.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: stores, page: page, per_page: per_page) do |store|
      create_dto(store)
    end
  end

  def ids(criteria: {})
    apply_scopes(criteria: criteria).ids
  end

  def pluck(criteria: {}, field:)
    apply_scopes(criteria: criteria).pluck(field)
  end

  def create_dto(store)
    return unless store
    Stores::StoreDTO.new(
      id: store.id,
      name: store.name,
      name_en: store.name_en,
      name_ar: store.name_ar,
      latitude: store.latitude,
      longitude: store.longitude,
      backend_id: store.backend_id,
      brand_id: store.brand_id,
      brand: Brands::BrandService.new.create_dto(store.brand),
      platform_stores: store.platform_stores.map do |platform_store|
        Stores::PlatformStoreService.new.create_dto(platform_store)
      end,
      status: {
        status: store.store_status&.status || "temporary_busy",
        reopen_at: store.store_status&.reopen_at,
        last_connected_at: Stores::StoreStatusService.new.get_last_connected_at(store_id: store.id),
        connectivity_status: store&.store_status&.connectivity_status,
      },
      contact_number: store.contact_number,
      contact_name: store.contact_name,
      description: store.description,
      description_en: store.description_en,
      description_ar: store.description_ar,
      approved: store.approved,
      deleted_at: store.deleted_at,
      company_id: store.company_id,
      city: Cities::CityService.new.create_dto(store.city),
    )
  end

  def create_light_dto(store)
    return unless store
    Stores::StoreDTO.new(
      id: store.id,
      name: store.name,
      name_en: store.name_en,
      name_ar: store.name_ar,
      latitude: store.latitude,
      longitude: store.longitude,
      backend_id: store.backend_id,
      brand_id: store.brand_id,
      deleted_at: store.deleted_at,
      company_id: store.company_id,
      delivery_type: store.delivery_type,
      city: Cities::CityService.new.create_dto(store.city)
    )
  end

  def publish_pubsub_by_brand(brand_id:, data: {})
    stores = Stores::Store.by_brand(brand_id).includes(:translations)

    stores.each do |store|
      working_hours_pub_sub(store: store, data: data)
    end
  end

  def publish_pubsub_by_store(store_id:, data: {})
    store = Stores::Store.find_by(id: store_id)
    working_hours_pub_sub(store: store, data: data) if store
  end

  private

  def publish_pubsub(data: {}, event:, topic:)
    Stores::PubSub::Publish.new.publish_store(data: data, event: event, topic: topic)
  end

  def working_hours_pub_sub(store:, data: {})
    Stores::PubSub::Publish.new.update_working_times(data: data.merge({store_primary_id: store.id}), status: :working_hours_updated)
  end

  def apply_scopes(criteria: {})
    stores = Stores::Store.where(nil)
    stores = stores.by_id(criteria[:id]) if criteria[:id].present?
    stores = stores.by_brand(criteria[:brand_id]) if criteria[:brand_id].present?
    stores = stores.by_backend_id(criteria[:backend_id]) if criteria[:backend_id].present?
    stores = stores.by_similar_name(criteria[:similar_name]) if criteria[:similar_name].present?
    stores = stores.by_company_id(criteria[:company_id]) if criteria[:company_id].present?
    stores = stores.by_location_radius(criteria[:latitude], criteria[:longitude], criteria[:radius]) if criteria[:latitude].present? && criteria[:longitude].present?
    stores = stores.by_similar_city_name(criteria[:city]) if criteria[:city].present?
    stores = stores.by_soft_deleted if criteria[:deleted].present?
    stores = stores.by_not_soft_deleted if criteria[:deleted].nil?
    stores = stores.by_approval(to_boolean(criteria[:approved])) if criteria.key?(:approved)
    stores = stores.includes(:platform_stores, :store_status, :city)
    stores = stores.where(platform_stores: {platform_id: criteria[:platform_id]}) if criteria[:platform_id].present?
    stores = stores.where(store_statuses: {status: criteria[:status]}) if criteria[:status].present?

    stores
  end

  def to_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
