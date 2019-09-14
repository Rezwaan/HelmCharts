class Catalogs::CatalogVariantService
  def create(attributes:)
    catalog_variant = Catalogs::CatalogVariant.new(attributes)
    catalog_variant.catalog_key = SecureRandom.uuid
    is_variant = true

    if catalog_variant.save
      Catalogs::Workers::FirebaseCreator.perform_async(catalog_variant.id, is_variant)
      return create_dto(catalog_variant)
    else
      return catalog_variant.errors
    end
  end

  def fetch(id)
    catalog_variant = Catalogs::CatalogVariant.where(id: id).not_deleted.first
    return nil unless catalog_variant
    create_dto(catalog_variant)
  end

  def create_dto(catalog_variant)
    attrs = {
      id: catalog_variant.id,
      name: catalog_variant.name,
      catalog_id: catalog_variant.catalog_id,
      firestore: {
        collection: collection_name,
        document_id: catalog_variant.id.to_s,
        document_path: "#{collection_name}/#{catalog_variant.catalog_id}/versions/#{catalog_variant.id}",
      },
    }

    Catalogs::CatalogDTO.new(attrs)
  end

  private

  def collection_name
    "dome_lite.catalogs"
  end
end
