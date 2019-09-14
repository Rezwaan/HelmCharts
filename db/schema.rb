# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_06_141414) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_enum :rush_delivery_status, [
    "unassigned",
    "assigned",
    "enroute_to_branch",
    "at_the_branch",
    "picked_up",
    "enroute_to_customer",
    "delivered",
    "canceled",
    "failed_to_assign",
    "near_pick_up",
    "near_delivery",
    "left_pick_up",
    "pre_assigned",
    "returned",
    "waiting_pickup_confirmation",
    "pickup_confirmed",
    "at_delivery",
    "left_delivery",
  ]

  create_table "account_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "role"
    t.string "role_resource_type"
    t.bigint "role_resource_id"
    t.uuid "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_roles_on_account_id"
    t.index ["role_resource_type", "role_resource_id"], name: "index_account_roles_on_role_resource_type_and_role_resource_id"
  end

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "username", default: "", null: false
    t.string "old_password_digest", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "email"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "current_sign_in_at"
    t.string "encrypted_password", default: "", null: false
    t.index ["confirmation_token"], name: "index_accounts_on_confirmation_token", unique: true
    t.index ["reset_password_token"], name: "index_accounts_on_reset_password_token", unique: true
    t.index ["username"], name: "index_accounts_on_username", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "app_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "device_type", null: false
    t.integer "build_number"
    t.string "version_key"
    t.integer "update_action", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_type", "build_number", "version_key"], name: "unique_app_version_history", unique: true
  end

  create_table "brand_brand_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "brand_id"
    t.bigint "brand_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_category_id"], name: "index_brand_brand_categories_on_brand_category_id"
    t.index ["brand_id", "brand_category_id"], name: "index_brand_brand_categories_on_brand_id_and_brand_category_id", unique: true
    t.index ["brand_id"], name: "index_brand_brand_categories_on_brand_id"
  end

  create_table "brand_categories", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_brand_categories_on_key", unique: true
  end

  create_table "brand_category_translations", force: :cascade do |t|
    t.integer "brand_category_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "plural_name"
    t.index ["brand_category_id"], name: "index_brand_category_translations_on_brand_category_id"
    t.index ["locale"], name: "index_brand_category_translations_on_locale"
  end

  create_table "brand_translations", force: :cascade do |t|
    t.integer "brand_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["brand_id"], name: "index_brand_translations_on_brand_id"
    t.index ["locale"], name: "index_brand_translations_on_locale"
  end

  create_table "brands", force: :cascade do |t|
    t.bigint "platform_id"
    t.string "backend_id"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "flags", default: 0, null: false
    t.bigint "brand_category_id"
    t.uuid "company_id"
    t.bigint "country_id"
    t.string "cover_photo_url"
    t.index ["brand_category_id"], name: "index_brands_on_brand_category_id"
    t.index ["company_id"], name: "index_brands_on_company_id"
    t.index ["country_id"], name: "index_brands_on_country_id"
    t.index ["platform_id"], name: "index_brands_on_platform_id"
  end

  create_table "catalog_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "catalog_id"
    t.string "related_to_type"
    t.bigint "related_to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalog_id"], name: "index_catalog_assignments_on_catalog_id"
    t.index ["related_to_type", "related_to_id"], name: "index_catalog_assignments_on_related_to_type_and_related_to_id"
  end

  create_table "catalog_variants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "catalog_id"
    t.string "catalog_key", null: false
    t.integer "priority", default: 0
    t.integer "start_from_minutes"
    t.integer "end_at_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.datetime "deleted_at"
    t.index ["catalog_id"], name: "index_catalog_variants_on_catalog_id"
    t.index ["catalog_key"], name: "index_catalog_variants_on_catalog_key"
  end

  create_table "catalogs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.bigint "brand_id"
    t.string "catalog_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["brand_id"], name: "index_catalogs_on_brand_id"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name", null: false
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_cities_on_name"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "registration_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.bigint "country_id"
    t.index ["country_id"], name: "index_companies_on_country_id"
  end

  create_table "company_translations", force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["company_id"], name: "index_company_translations_on_company_id"
    t.index ["locale"], name: "index_company_translations_on_locale"
  end

  create_table "countries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.integer "currency_id"
  end

  create_table "country_translations", force: :cascade do |t|
    t.integer "country_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["country_id"], name: "index_country_translations_on_country_id"
    t.index ["locale"], name: "index_country_translations_on_locale"
  end

  create_table "customer_addresses", force: :cascade do |t|
    t.string "backend_id", null: false
    t.bigint "customer_id", null: false
    t.decimal "latitude", precision: 10, scale: 8, null: false
    t.decimal "longitude", precision: 11, scale: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "backend_id"], name: "index_customer_addresses_on_customer_id_and_backend_id", unique: true
    t.index ["customer_id"], name: "index_customer_addresses_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "platform_id", null: false
    t.string "backend_id", null: false
    t.string "name"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform_id", "backend_id"], name: "index_customers_on_platform_id_and_backend_id", unique: true
    t.index ["platform_id"], name: "index_customers_on_platform_id"
  end

  create_table "devices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "installation_uid", null: false
    t.text "auth_id", null: false
    t.string "auth_key", null: false
    t.boolean "enabled", null: false
    t.integer "device_type", null: false
    t.text "os"
    t.text "idfa"
    t.text "idfv"
    t.text "mac"
    t.text "android_id"
    t.text "gps_adid"
    t.text "imei"
    t.text "fcm_token"
    t.text "apn_token"
    t.boolean "enable_notifications"
    t.geography "current_lonlat", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.float "current_location_accuracy"
    t.integer "language", null: false
    t.datetime "last_opened_at", null: false
    t.inet "last_opened_ip", null: false
    t.inet "created_ip", null: false
    t.string "device_manufacturer"
    t.string "device_model"
    t.boolean "keep_service_alive", default: true
    t.uuid "app_version_id"
    t.bigint "device_usage", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "account_id"
    t.boolean "fcm_token_not_found", default: false
    t.index ["account_id"], name: "index_devices_on_account_id"
    t.index ["app_version_id"], name: "index_devices_on_app_version_id"
    t.index ["app_version_id"], name: "index_rider_devices_on_app_version_id"
    t.index ["auth_id"], name: "index_rider_devices_on_auth_id", unique: true
  end

  create_table "integration_catalog_overrides", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_catalog_id"
    t.string "item_id"
    t.string "item_type"
    t.jsonb "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_catalog_id", "item_type", "item_id"], name: "integration_catalog_overrides_item_id_uniqueness", unique: true
    t.index ["integration_catalog_id"], name: "index_integration_catalog_overrides_on_integration_catalog_id"
  end

  create_table "integration_catalogs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_host_id"
    t.uuid "catalog_id"
    t.jsonb "external_data"
    t.string "external_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalog_id"], name: "index_integration_catalogs_on_catalog_id"
    t.index ["integration_host_id", "external_reference"], name: "integration_catalogs_external_reference_uniqness", unique: true
    t.index ["integration_host_id"], name: "index_integration_catalogs_on_integration_host_id"
  end

  create_table "integration_hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.jsonb "config"
    t.integer "integration_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true, null: false
  end

  create_table "integration_id_mappings", force: :cascade do |t|
    t.text "str", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["str"], name: "index_integration_id_mappings_on_str", unique: true
  end

  create_table "integration_order_statuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_order_id"
    t.string "status"
    t.jsonb "external_data", default: "nil"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_order_id"], name: "index_integration_order_statuses_on_integration_order_id"
  end

  create_table "integration_orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_host_id"
    t.jsonb "external_data"
    t.bigint "order_id"
    t.integer "status"
    t.string "external_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["integration_host_id"], name: "index_integration_orders_on_integration_host_id"
    t.index ["order_id"], name: "index_integration_orders_on_order_id"
  end

  create_table "integration_stores", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "integration_host_id"
    t.string "external_reference"
    t.jsonb "external_data"
    t.bigint "store_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true, null: false
    t.index ["integration_host_id", "external_reference"], name: "integration_stores_external_reference_uniqness", unique: true
    t.index ["integration_host_id"], name: "index_integration_stores_on_integration_host_id"
    t.index ["store_id"], name: "index_integration_stores_on_store_id", unique: true
  end

  create_table "manufacturer_translations", force: :cascade do |t|
    t.uuid "manufacturer_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_manufacturer_translations_on_locale"
    t.index ["manufacturer_id"], name: "index_manufacturer_translations_on_manufacturer_id"
  end

  create_table "manufacturers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_line_item_modifier_translations", force: :cascade do |t|
    t.integer "order_line_item_modifier_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.text "group"
    t.index ["locale"], name: "index_order_line_item_modifier_translations_on_locale"
    t.index ["order_line_item_modifier_id"], name: "index_7919993e156174d247643a0df82fbb236b94e6e3"
  end

  create_table "order_line_item_modifiers", force: :cascade do |t|
    t.bigint "order_line_item_id"
    t.float "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_reference"
    t.index ["order_line_item_id"], name: "index_order_line_item_modifiers_on_order_line_item_id"
  end

  create_table "order_line_item_translations", force: :cascade do |t|
    t.integer "order_line_item_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.text "description"
    t.index ["locale"], name: "index_order_line_item_translations_on_locale"
    t.index ["order_line_item_id"], name: "index_order_line_item_translations_on_order_line_item_id"
  end

  create_table "order_line_items", force: :cascade do |t|
    t.bigint "order_id"
    t.string "backend_id", null: false
    t.float "quantity"
    t.decimal "total_price", precision: 10, scale: 2
    t.string "image"
    t.decimal "discount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_reference"
    t.jsonb "item_detail"
    t.index ["order_id"], name: "index_order_line_items_on_order_id"
  end

  create_table "order_notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "order_id"
    t.text "note"
    t.integer "note_type"
    t.string "author_category"
    t.string "author_entity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_notes_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "backend_id", null: false
    t.string "order_key", null: false
    t.integer "status", default: 1, null: false
    t.text "customer_notes"
    t.decimal "amount", precision: 10, scale: 2
    t.decimal "discount", precision: 10, scale: 2
    t.decimal "delivery_fee", precision: 10, scale: 2
    t.decimal "collect_at_customer", precision: 10, scale: 2
    t.decimal "collect_at_pickup", precision: 10, scale: 2
    t.boolean "offer_applied", default: false
    t.string "coupon"
    t.boolean "returnable", default: false
    t.string "return_code"
    t.string "returned_status"
    t.integer "payment_type", default: 1
    t.integer "order_type", default: 1
    t.bigint "customer_id", null: false
    t.bigint "customer_address_id", null: false
    t.bigint "store_id", null: false
    t.bigint "platform_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "currency_id"
    t.bigint "reject_reason_id"
    t.integer "transmission_medium", default: 1, null: false
    t.index ["currency_id"], name: "index_orders_on_currency_id"
    t.index ["customer_address_id"], name: "index_orders_on_customer_address_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["platform_id", "backend_id"], name: "index_orders_on_platform_id_and_backend_id", unique: true
    t.index ["platform_id"], name: "index_orders_on_platform_id"
    t.index ["reject_reason_id"], name: "index_orders_on_reject_reason_id"
    t.index ["store_id"], name: "index_orders_on_store_id"
  end

  create_table "platform_stores", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "store_id", null: false
    t.bigint "platform_id", null: false
    t.integer "status", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform_id", "store_id"], name: "index_platform_stores_on_platform_id_and_store_id", unique: true
    t.index ["platform_id"], name: "index_platform_stores_on_platform_id"
    t.index ["store_id"], name: "index_platform_stores_on_store_id"
  end

  create_table "platform_translations", force: :cascade do |t|
    t.integer "platform_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.index ["locale"], name: "index_platform_translations_on_locale"
    t.index ["platform_id"], name: "index_platform_translations_on_platform_id"
  end

  create_table "platforms", force: :cascade do |t|
    t.string "backend_id", null: false
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_attribute_option_translations", force: :cascade do |t|
    t.uuid "product_attribute_option_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_product_attribute_option_translations_on_locale"
    t.index ["product_attribute_option_id"], name: "index_e7137381f48d03582acd057d550571bf98b66ef9"
  end

  create_table "product_attribute_options", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_attribute_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_attribute_id"], name: "index_product_attribute_options_on_product_attribute_id"
  end

  create_table "product_attribute_translations", force: :cascade do |t|
    t.uuid "product_attribute_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_product_attribute_translations_on_locale"
    t.index ["product_attribute_id"], name: "index_product_attribute_translations_on_product_attribute_id"
  end

  create_table "product_attribute_values", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_attribute_option_id"
    t.uuid "variant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_attribute_option_id"], name: "index_product_attribute_values_on_product_attribute_option_id"
    t.index ["variant_id"], name: "index_product_attribute_values_on_variant_id"
  end

  create_table "product_attributes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id"
    t.uuid "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_tags_on_product_id"
    t.index ["tag_id"], name: "index_product_tags_on_tag_id"
  end

  create_table "product_translations", force: :cascade do |t|
    t.uuid "product_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "description"
    t.index ["locale"], name: "index_product_translations_on_locale"
    t.index ["product_id"], name: "index_product_translations_on_product_id"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "prototype_id"
    t.float "default_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "manufacturer_id"
    t.index ["manufacturer_id"], name: "index_products_on_manufacturer_id"
    t.index ["prototype_id"], name: "index_products_on_prototype_id"
  end

  create_table "prototype_attributes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "prototype_id"
    t.uuid "product_attribute_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_attribute_id"], name: "index_prototype_attributes_on_product_attribute_id"
    t.index ["prototype_id"], name: "index_prototype_attributes_on_prototype_id"
  end

  create_table "prototype_translations", force: :cascade do |t|
    t.uuid "prototype_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_prototype_translations_on_locale"
    t.index ["prototype_id"], name: "index_prototype_translations_on_prototype_id"
  end

  create_table "prototypes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rush_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "drop_off_longitude", precision: 10, scale: 6, null: false
    t.decimal "drop_off_latitude", precision: 10, scale: 6, null: false
    t.text "drop_off_description", null: false
    t.decimal "pick_up_latitude", precision: 10, scale: 6, null: false
    t.decimal "pick_up_longitude", precision: 10, scale: 6, null: false
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "status", default: "unassigned", enum_name: "rush_delivery_status"
    t.index ["order_id"], name: "index_rush_deliveries_on_order_id"
  end

  create_table "store_item_availabilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "store_id", null: false
    t.uuid "catalog_id", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expiry_at"
    t.index ["catalog_id", "store_id", "item_id"], name: "catalog_store_items_uniqness", unique: true
    t.index ["catalog_id"], name: "index_store_item_availabilities_on_catalog_id"
    t.index ["item_id"], name: "index_store_item_availabilities_on_item_id"
    t.index ["store_id"], name: "index_store_item_availabilities_on_store_id"
  end

  create_table "store_statuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "store_id", null: false
    t.integer "status", default: 1, null: false
    t.datetime "reopen_at"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "connectivity_status", default: 2
    t.index ["store_id"], name: "index_store_statuses_on_store_id"
  end

  create_table "store_translations", force: :cascade do |t|
    t.integer "store_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name"
    t.text "description"
    t.index ["locale"], name: "index_store_translations_on_locale"
    t.index ["store_id"], name: "index_store_translations_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.string "backend_id"
    t.decimal "latitude", precision: 10, scale: 8, null: false
    t.decimal "longitude", precision: 11, scale: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "flags", default: 0
    t.string "contact_number"
    t.uuid "company_id"
    t.datetime "deleted_at"
    t.string "contact_name"
    t.bigint "city_id"
    t.index ["brand_id"], name: "index_stores_on_brand_id"
    t.index ["city_id"], name: "index_stores_on_city_id"
    t.index ["company_id"], name: "index_stores_on_company_id"
    t.index ["deleted_at"], name: "index_stores_on_deleted_at"
  end

  create_table "tag_translations", force: :cascade do |t|
    t.uuid "tag_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_tag_translations_on_locale"
    t.index ["tag_id"], name: "index_tag_translations_on_tag_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "store_id", null: false
    t.integer "task_type", null: false
    t.integer "status", default: 1, null: false
    t.string "related_to_type"
    t.bigint "related_to_id"
    t.datetime "expiry_at"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_tasks_on_store_id"
  end

  create_table "ticket_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "ticket_id"
    t.string "file_attachment_file_name"
    t.string "file_attachment_content_type"
    t.bigint "file_attachment_file_size"
    t.datetime "file_attachment_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_ticket_attachments_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.integer "ticket_type", null: false
    t.jsonb "data", default: {}, null: false
    t.string "related_to_type"
    t.uuid "related_to_id"
    t.string "creator_type", null: false
    t.uuid "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_type", "creator_id"], name: "index_tickets_on_creator_type_and_creator_id"
    t.index ["related_to_type", "related_to_id"], name: "index_tickets_on_related_to_type_and_related_to_id"
    t.index ["ticket_type"], name: "index_tickets_on_ticket_type"
  end

  create_table "variant_translations", force: :cascade do |t|
    t.uuid "variant_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["locale"], name: "index_variant_translations_on_locale"
    t.index ["variant_id"], name: "index_variant_translations_on_variant_id"
  end

  create_table "variants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id"
    t.string "sku"
    t.float "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
  end

  create_table "week_working_times", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "working_time_rule_id"
    t.integer "weekday", null: false
    t.integer "start_from_minutes", null: false
    t.integer "end_at_minutes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["working_time_rule_id"], name: "index_week_working_times_on_working_time_rule_id"
  end

  create_table "working_time_rule_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "working_time_rule_id"
    t.string "related_to_type"
    t.bigint "related_to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["related_to_type", "related_to_id"], name: "index_working_time_rule_assignments_on_related_to"
    t.index ["working_time_rule_id"], name: "index_working_time_rule_assignments_on_working_time_rule_id"
  end

  create_table "working_time_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "zendesk_tickets", force: :cascade do |t|
    t.string "zendesk_reference_id"
    t.string "related_to_type"
    t.bigint "related_to_id"
    t.bigint "ticket_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["related_to_type", "related_to_id"], name: "index_zendesk_tickets_on_related_to_type_and_related_to_id"
    t.index ["ticket_id"], name: "index_zendesk_tickets_on_ticket_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "brand_brand_categories", "brand_categories"
  add_foreign_key "brand_brand_categories", "brands"
  add_foreign_key "brands", "brand_categories"
  add_foreign_key "brands", "countries"
  add_foreign_key "brands", "platforms"
  add_foreign_key "catalog_assignments", "catalogs"
  add_foreign_key "catalogs", "brands"
  add_foreign_key "customer_addresses", "customers"
  add_foreign_key "integration_catalog_overrides", "integration_catalogs"
  add_foreign_key "integration_catalogs", "catalogs"
  add_foreign_key "integration_catalogs", "integration_hosts"
  add_foreign_key "integration_order_statuses", "integration_orders"
  add_foreign_key "integration_orders", "integration_hosts"
  add_foreign_key "integration_orders", "orders"
  add_foreign_key "integration_stores", "integration_hosts"
  add_foreign_key "integration_stores", "stores"
  add_foreign_key "order_line_item_modifiers", "order_line_items"
  add_foreign_key "order_line_items", "orders"
  add_foreign_key "order_notes", "orders"
  add_foreign_key "orders", "customer_addresses"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "platforms"
  add_foreign_key "orders", "stores"
  add_foreign_key "platform_stores", "platforms"
  add_foreign_key "platform_stores", "stores"
  add_foreign_key "product_attribute_options", "product_attributes"
  add_foreign_key "product_attribute_values", "product_attribute_options"
  add_foreign_key "product_attribute_values", "variants"
  add_foreign_key "product_tags", "products"
  add_foreign_key "product_tags", "tags"
  add_foreign_key "products", "manufacturers"
  add_foreign_key "products", "prototypes"
  add_foreign_key "prototype_attributes", "product_attributes"
  add_foreign_key "prototype_attributes", "prototypes"
  add_foreign_key "rush_deliveries", "orders"
  add_foreign_key "store_statuses", "stores"
  add_foreign_key "stores", "brands"
  add_foreign_key "tasks", "stores"
  add_foreign_key "ticket_attachments", "tickets"
  add_foreign_key "variants", "products"
  add_foreign_key "week_working_times", "working_time_rules"
  add_foreign_key "working_time_rule_assignments", "working_time_rules"
  add_foreign_key "zendesk_tickets", "tickets"
end
