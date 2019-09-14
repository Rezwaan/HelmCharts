class Devices::Device < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :app_version, optional: true, class_name: "AppVersions::AppVersion"

  scope :by_auth_key, ->(auth_key) { where(auth_key: auth_key) }
  scope :by_auth_id, ->(auth_id) { where(auth_id: auth_id) }
  scope :by_installation_id, ->(installation_id) { where(installation_id: installation_id) }
  scope :by_account_id, ->(account_id) { where(account_id: account_id) }
  scope :by_enabled, ->(enabled) { where(enabled: enabled) }
  scope :by_id, ->(id) { where(id: id) }
  scope :by_fcm_token_present, ->(fcm_token_present) { ActiveRecord::Type::Boolean.new.deserialize(fcm_token_present) ? where("#{table_name}.fcm_token IS NOT NULL AND #{table_name}.fcm_token <> ''") : where("#{table_name}.fcm_token IS NULL OR #{table_name}.fcm_token = ''") }
  scope :by_apn_token_present, ->(apn_token_present) { ActiveRecord::Type::Boolean.new.deserialize(apn_token_present) ? where("#{table_name}.apn_token IS NOT NULL AND #{table_name}.apn_token <> ''") : where("#{table_name}.apn_token IS NULL OR #{table_name}.apn_token = ''") }
  scope :by_fcm_token_not_found, ->(fcm_token_not_found) { where(fcm_token_not_found: ActiveRecord::Type::Boolean.new.deserialize(fcm_token_not_found)) }
  scope :by_device_type, ->(device_type) { where(device_type: device_type) }

  validates :language, presence: true
  validates :last_opened_ip, presence: true
  validates :created_ip, presence: true

  enum language: {ar: 1, en: 2, ur: 3}
  enum device_type: {android: 1, ios: 2}
end
