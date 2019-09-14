class Catalogs::Workers::FirebaseCreator
  include Sidekiq::Worker

  def perform(catalog_id, is_variant)
    firebase_bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)

    catalog = if is_variant
      Catalogs::CatalogVariantService.new.fetch(catalog_id)
    else
      Catalogs::CatalogService.new.fetch(catalog_id)
    end

    data = {
      "bundle_sets": {},
      "bundles": {},
      "categories": {},
      "customization_ingredient_items": {},
      "customization_ingredients": {},
      "customization_option_items": {},
      "customization_options": {},
      "item_bundles": {},
      "item_sets": {},
      "items": {},
      "name": catalog.name,
      "products": {},
      "sets": {},
    }
    firebase_bot.create_document(path: catalog.firestore[:document_path], data: data)
  end
end
