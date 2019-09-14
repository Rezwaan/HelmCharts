class Admin::Presenters::Catalogs::Show
  def initialize(catalog)
    @catalog = catalog
  end

  def present(firebase_config: nil)
    res = {
      id: @catalog.id,
      name: @catalog.name,
      firebase_config: firebase_config && {
        apiKey: firebase_config[:apiKey],
        authDomain: firebase_config[:authDomain],
        projectId: firebase_config[:projectId],
        token: firebase_config[:token],
        document_path: @catalog.firestore[:document_path],
        collection: @catalog.firestore[:collection],
        document_id: @catalog.firestore[:document_id],
      },
      store_assignments: @catalog.store_assignments,
      brand_assignments: @catalog.brand_assignments,
    }

    if @catalog[:catalog_versions]
      res[:catalog_versions] = @catalog[:catalog_versions].map { |catalog_version| {id: catalog_version.id, created_at: catalog_version.created_at.to_i} }
    end

    res
  end
end
