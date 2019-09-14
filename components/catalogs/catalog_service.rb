class Catalogs::CatalogService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    catalog = Catalogs::Catalog.new(name: attributes["name"], brand_id: attributes["brand_id"])
    catalog.catalog_key = SecureRandom.uuid
    is_variant = false
    if catalog.save
      Catalogs::Workers::FirebaseCreator.perform_async(catalog.id, is_variant)
      return create_dto(catalog)
    else
      return catalog.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc", light: true)
    catalogs = Catalogs::Catalog.not_deleted
    catalogs = catalogs.by_id(criteria[:id]) if criteria[:id].present?
    catalogs = catalogs.by_brand(criteria[:brand_id]) if criteria[:brand_id].present?
    catalogs = catalogs.by_name(criteria[:name]) if criteria[:name].present?
    catalogs = catalogs.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: catalogs, page: page, per_page: per_page) do |catalog|
      create_dto(catalog, light: light)
    end
  end

  def fetch(id, light: true)
    catalog = Catalogs::Catalog.where(id: id).not_deleted.first
    return nil unless catalog
    create_dto(catalog, light: light)
  end

  def delete(id)
    catalog = Catalogs::Catalog.where(id: id).not_deleted.first
    return nil unless catalog
    catalog.destroy
  end

  def firebase_document(document_path:, additional_data:)
    bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
    catalog_data = bot.fetch_document(path: document_path) || {}
    catalog_version_id = SecureRandom.uuid
    version_path = "dome_lite.catalog_versions/#{catalog_version_id}"
    version_data = catalog_data.merge(additional_data)
    bot.create_document(path: version_path, data: version_data)

    catalog_data
  end

  # Returns:
  # - A catalog DTO if publishing goes fine.
  # - nil if the catalog was not found
  # - TODO: An array of errors if the fetched catalog from Firestore has any errors
  def publish(id, publisher={})
    catalog = Catalogs::Catalog.where(id: id).not_deleted.first

    return nil unless catalog

    document_path = "#{collection_name}/#{catalog.id}"
    additional_data = {catalog_id: catalog.id, created_at: Time.now.to_i, publisher: publisher}
    catalog_data = firebase_document(document_path: document_path, additional_data: additional_data)
    version_data = catalog_data.merge(additional_data)

    # TODO: Return this once our validator setup is done and we're sure we've done
    # the necessary changes to catalog structure.
    # errors = validate_catalog(catalog)
    # return errors if errors && errors.length > 0

    if catalog_data.present?
      menu_ar = Catalogs::CatalogSerializer.new(catalog_data, lang: "ar").menu
      menu_en = Catalogs::CatalogSerializer.new(catalog_data, lang: "en").menu
      catalog_menu_variants = catalog_variants_data(catalog: catalog)

      publish_version(catalog_version: version_data, catalog_en: menu_en, catalog_ar: menu_ar, catalog_variants: catalog_menu_variants)
    end

    create_dto(catalog)
  end

  def publish_version(catalog_version:, catalog_en:, catalog_ar:, catalog_variants: {})
    # Store a new version in catalog.lite
    brand_ids = Catalogs::CatalogAssignment.where(catalog_id: catalog_version[:catalog_id], related_to_type: "Brands::Brand").pluck(:related_to_id)

    store_ids = Catalogs::CatalogAssignment.where(catalog_id: catalog_version[:catalog_id], related_to_type: "Stores::Store").pluck(:related_to_id)

    return if brand_ids.blank? && store_ids.blank?
    event_data = {
      catalog_version_id: catalog_version[:id],
      catalog_id: catalog_version[:catalog_id],
      brand_primary_ids: brand_ids,
      store_primary_ids: store_ids,
      menu_ar: catalog_ar,
      menu_en: catalog_en,
      catalog_menu_variants: catalog_variants,
    }

    Catalogs::PubSub::Publish.new.catalog_updated(data: event_data, update: :content_updated)
  end

  def catalog_versions(catalog_id)
    bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
    result = bot.filter(
      collection: "dome_lite.catalog_versions",
      criteria: [{field: "catalog_id", operator: "=", value: catalog_id}],
      fields: [:created_at, :catalog_id],
    )
    result
  end

  def catalog_preview(catalog:, language: "en")
    document_path = "#{collection_name}/#{catalog.id}"
    bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
    catalog_data = bot.fetch_document(path: document_path) || {}
    menu = catalog_data ? Catalogs::CatalogSerializer.new(catalog_data, lang: language).menu : {}
    unavailable_item_ids = StoreItemAvailabilities::StoreItemAvailabilityService.new.by_catalog(catalog_id: catalog.id)

    {id: 1, version: 1, schema: 0, currency: "SAR", unavailable_item_ids: unavailable_item_ids, data: menu}
  end

  # Returns an array of errors or an empty array
  def validate_catalog(catalog)
    validator = CatalogSchemas::Dome::Validators::Catalog.new

    validator&.full_validation(catalog)
  end

  private

  def create_dto(catalog, light: true)
    attrs = {
      id: catalog.id,
      name: catalog.name,
      brand_id: catalog.brand_id,
      firestore: {
        collection: collection_name,
        document_id: catalog.id.to_s,
        document_path: "#{collection_name}/#{catalog.id}",
      },
    }

    if light == false
      attrs[:catalog_versions] = catalog_versions(catalog.id).map { |catalog_version| create_catalog_version_dto(catalog_version) }
      attrs.merge!(Catalogs::CatalogAssignmentService.new.assignments_count_type(catalog_id: catalog.id))
    end

    Catalogs::CatalogDTO.new(attrs)
  end

  def create_catalog_version_dto(catalog_version)
    Catalogs::CatalogVersionDTO.new({created_at: catalog_version.created_at, id: catalog_version.document_id})
  end

  def collection_name
    "dome_lite.catalogs"
  end

  def catalog_variants_data(catalog:)
    catalog.catalog_variants.map do |catalog_variant|
      document_path = "#{collection_name}/#{catalog.id}/versions/#{catalog_variant.id}"
      additional_data = {catalog_id: catalog.id, created_at: Time.now.to_i}
      catalog_data = firebase_document(document_path: document_path, additional_data: additional_data)

      if catalog_data.present?
        menu_ar = Catalogs::CatalogSerializer.new(catalog_data, lang: "ar").menu
        menu_en = Catalogs::CatalogSerializer.new(catalog_data, lang: "en").menu

        {
          menu_ar: menu_ar,
          menu_en: menu_en,
          priority: catalog_variant.priority,
          start_from_minutes: catalog_variant.start_from_minutes,
          end_at_minutes: catalog_variant.end_at_minutes,
        }
      else
        {}
      end
    end
  end
end
