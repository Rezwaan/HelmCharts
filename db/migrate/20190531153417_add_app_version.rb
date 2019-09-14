class AddAppVersion < ActiveRecord::Migration[5.2]
  def change
    create_table "app_versions", id: :uuid, force: :cascade do |t|
      t.integer "device_type", null: false
      t.integer "build_number"
      t.string "version_key"
      t.integer "update_action", default: 1, null: false
      t.timestamps null: false
      t.index ["device_type", "build_number", "version_key"], name: "unique_app_version_history", unique: true
    end
  end
end
