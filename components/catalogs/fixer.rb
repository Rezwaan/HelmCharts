# Fixes common issues described in:
# https://themakersteam.atlassian.net/browse/DOME-208
class Catalogs::Fixer
  attr_reader :original_catalog, :fixed_catalog

  FIRESTORE_COLLECTION_NAME = "dome_lite.catalogs"

  # If catalog is passed in (ideal for local use), it will turn it into a HashWithIndifferentAccess
  # If catalog_id is passed in (ideal for production use), it will get it from the database or log an error, and
  # if it finds it, it will fetch the catalog from FireStore and turn it into a HashWithIndifferentAccess.
  #
  # @param [String] catalog_id A string UUID of a catalog (Searches through the table linked to Catalogs::Catalog for it)
  # @param [Hash] catalog A catalog retrieved from Firestore as JSON then parsed into a Ruby hash
  def initialize(catalog_id: "", catalog: {})
    @firestore_document_path = ""

    if catalog.length.positive?
      @original_catalog = catalog.with_indifferent_access
      @fixed_catalog = @original_catalog

    elsif catalog_id.length.positive?
      unless Catalogs::Catalog.find(catalog_id)
        Rails.logger.error("Catalogs::Fixer - Unable to find catalog #{catalog_id}")
        return
      end

      @firestore_document_path = "#{FIRESTORE_COLLECTION_NAME}/#{catalog_id}"
      @original_catalog = fetch_catalog_from_firestore

    else
      Rails.logger.error("Catalogs::Fixer - Unknown input")
    end

    @fixed_catalog = @original_catalog
  end

  # Fixes common issues found in a catalog. If the catalog was originally
  # fetched from Firestore, it will overwrite it.
  # @return [HashWithIndifferentAccess] The fixed catalog
  def fix
    fix_items
    fix_bundles
    fix_products
    fix_categories
    fix_item_bundles
    fix_customization_options
    fix_customization_option_items

    update_firestore_catalog if fetched_from_firestore?

    @fixed_catalog
  end

  private

  def fix_items
    @fixed_catalog[:items].each do |_, item|
      # Item reference names can sometimes not exist or be null, we'll add a
      # random hex string in that case.
      item[:reference_name] = SecureRandom.hex unless item[:reference_name]

      # Customization Option and Ingredient IDs can sometimes not exist
      item[:customization_option_ids] = {} unless item[:customization_option_ids]
      item[:customization_ingredient_ids] = {} unless item[:customization_ingredient_ids]
    end
  end

  def fix_bundles
    @fixed_catalog[:bundles].each do |_, bundle|
      # Bundles can sometimes have null descriptions
      bundle[:description] = "No description" unless bundle[:description]
      bundle[:description_ar] = "لا يوجد وصف" unless bundle[:description_ar]

      # Bundles can sometimes have string weights, they should be integers.
      bundle[:weight] = bundle[:weight].to_i
    end
  end

  def fix_products
    @fixed_catalog[:products].each do |_, product|
      # Product reference names can sometimes not exist or be null, we'll add a
      # random hex string in that case.
      product[:reference_name] = SecureRandom.hex unless product[:reference_name]

      # Products can sometimes have null descriptions
      product[:description] = "No description" unless product[:description]
      product[:description_ar] = "لا يوجد وصف" unless product[:description_ar]

      # Products can sometimes have string weights, they should be integers.
      product[:weight] = product[:weight].to_i

      # Products can sometimes have a null value in the images hash
      product[:images].each do |k, v|
        product[:images].delete(k) if v.nil?
      end
    end
  end

  def fix_categories
    @fixed_catalog[:categories].each do |_, category|
      # Categories can sometimes have string weights, they should be integers.
      category[:weight] = category[:weight].to_i

      # Categories can have a `products` property which shouldn't exist
      category.delete(:products)

      # Categories can have a `_showDetails` property which shouldn't exist
      category.delete("_showDetails")
    end
  end

  def fix_item_bundles
    @fixed_catalog[:item_bundles].each do |_, item_bundle|
      # Item bundles can sometimes have null descriptions
      item_bundle[:description] = "No description" unless item_bundle[:description]
      item_bundle[:description_ar] = "لا يوجد وصف" unless item_bundle[:description_ar]

      # Item bundles can sometimes have string weights, they should be integers.
      item_bundle[:weight] = item_bundle[:weight].to_i

      # Item bundles sometimes have integer prices, they should be strings.
      item_bundle[:price] = item_bundle[:price].to_s
    end
  end

  def fix_customization_options
    @fixed_catalog[:customization_options].each do |_, customization_option|
      # Customization options can sometimes have string max/min selection, they should be integers.
      customization_option[:max_selection] = customization_option[:max_selection].to_i
      customization_option[:min_selection] = customization_option[:min_selection].to_i

      # We don't currently use customization option images, and if you set
      # them, the iOS app will not be able to render the catalog.
      customization_option[:images] = {}

      # Customization options item IDs can sometimes have IDs with extra
      # properties, they should be look like { "id" => id.to_i }
      customization_option[:customization_option_item_ids] = customization_option[:customization_option_item_ids].map { |key, value|
        if value.is_a?(Hash)
          [key.to_s, key.to_i]
        else
          [key, value]
        end
      }.to_h
    end
  end

  def fix_customization_option_items
    @fixed_catalog[:customization_option_items].each do |_, customization_option_item|
      # Customization option items can sometimes have integer prices, they should be strings.
      customization_option_item[:price] = customization_option_item[:price].to_s

      # Customization option items can sometimes have string weights, they should be integers.
      customization_option_item[:weight] = customization_option_item[:weight].to_i

      # Customization option items can sometimes have a wrongly cased item_id
      if customization_option_item["itemId"] && !customization_option_item.key?(:item_id)
        customization_option_item[:item_id] = customization_option_item["itemId"]
        customization_option_item.delete("itemId")
      end

      # default_selected can be a string sometimes, ensure it's a boolean
      customization_option_item[:default_selected] =
        ActiveModel::Type::Boolean.new.cast(customization_option_item[:default_selected])
    end
  end

  def fetch_catalog_from_firestore
    catalog_data = firestore_bot.fetch_document(path: @firestore_document_path)

    parsed_json = JSON.parse(catalog_data.to_json)
    parsed_json.with_indifferent_access
  end

  def update_firestore_catalog
    firestore_bot.create_document(path: @firestore_document_path, data: @fixed_catalog)
  end

  def firestore_bot
    Firebase::Bot.new(config: Rails.application.secrets.firebase)
  end

  def fetched_from_firestore?
    @firestore_document_path.length > 0
  end
end
