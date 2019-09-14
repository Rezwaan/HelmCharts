class AddDeviceTable < ActiveRecord::Migration[5.2]
  def change
    create_table "devices", force: :cascade, id: :uuid do |t|
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
      t.geography "current_lonlat", limit: {srid: 4326, type: "st_point", geographic: true}
      t.float "current_location_accuracy"
      t.integer "language", null: false
      t.datetime "last_opened_at", null: false
      t.inet "last_opened_ip", null: false
      t.inet "created_ip", null: false
      t.references :account
      t.string "device_manufacturer"
      t.string "device_model"
      t.boolean "keep_service_alive", default: true
      t.references :app_version
      t.bigint "device_usage", default: 0, null: false
      t.timestamps null: false
      t.index ["app_version_id"], name: "index_rider_devices_on_app_version_id"
      t.index ["auth_id"], name: "index_rider_devices_on_auth_id", unique: true
      t.index ["account_id"], name: "index_rider_devices_on_account_id"
    end
  end
end
