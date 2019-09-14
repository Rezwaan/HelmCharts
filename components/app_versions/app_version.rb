# == Schema Information
#
# Table name: app_versions
#
#  id            :uuid             not null, primary key
#  build_number  :integer
#  device_type   :integer          not null
#  update_action :integer          default("no_update"), not null
#  version_key   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  unique_app_version_history  (device_type,build_number,version_key) UNIQUE
#

class AppVersions::AppVersion < ApplicationRecord
  enum update_action: {
    no_update: 1,
    recommended: 2,
    force: 3,
  }

  enum device_type: {android: 1, ios: 2}

  scope :by_id, ->(id) { where(id: id) }
  scope :by_search_key, ->(field_name, query) { SEARCHABLE_FIELDS[field_name] ? where("#{SEARCHABLE_FIELDS[field_name]} LIKE ?", "%#{query}%") : where(nil) }
  scope :by_build_number, ->(build_number) { where(build_number: build_number) }
  scope :by_device_type, ->(device_type) { where(device_type: device_type) }
  scope :by_version_key, ->(version_key) { where(version_key: version_key) }
  scope :by_update_action, ->(action) { where(update_action: action) }

  SEARCHABLE_FIELDS = {
    "build_number" => "CAST(app_versions.build_number AS VarChar(255))",
    "version_key" => "app_versions.version_key",
  }
end
