class Admin::Presenters::Catalogs::Token
  def initialize(catalog)
    @catalog = catalog
  end

  def present(firebase_config: nil, menu_url_en: nil, menu_url_ar: nil)
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
      menu_deeplinks: menu_url_en && menu_url_ar && generate_menu_deeplinks(catalog: @catalog, menu_url_en: menu_url_en, menu_url_ar: menu_url_ar),
    }

    res
  end

  def generate_menu_deeplinks(catalog:, menu_url_en:, menu_url_ar:)
    menu_url_en = URI.escape(menu_url_en)
    menu_url_ar = URI.escape(menu_url_ar)

    deeplink = "swyftapp://?screen=menu_preview"

    {
      preview_en: "#{deeplink}&menu_url=#{menu_url_en}",
      preview_ar: "#{deeplink}&menu_url=#{menu_url_ar}",
    }
  end
end
