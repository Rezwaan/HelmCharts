class Admin::Presenters::Catalogs::CatalogVariants::Show
  def initialize(catalog_variant)
    @catalog_variant = catalog_variant
  end

  def present(firebase_config: nil)
    res = {
      id: @catalog_variant.id,
      name: @catalog_variant.name,
      catalog_id: @catalog_variant.catalog_id,
      firebase_config: firebase_config && {
        apiKey: firebase_config[:apiKey],
        authDomain: firebase_config[:authDomain],
        projectId: firebase_config[:projectId],
        token: firebase_config[:token],
        document_path: @catalog_variant.firestore[:document_path],
        collection: @catalog_variant.firestore[:collection],
        document_id: @catalog_variant.firestore[:document_id],
      },
    }

    res
  end
end
