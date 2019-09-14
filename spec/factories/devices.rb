# == Schema Information
#
# Table name: devices
#
#  id                        :uuid             not null, primary key
#  apn_token                 :text
#  auth_key                  :string           not null
#  created_ip                :inet             not null
#  current_location_accuracy :float
#  device_manufacturer       :string
#  device_model              :string
#  device_type               :integer          not null
#  device_usage              :bigint           default(0), not null
#  enable_notifications      :boolean
#  enabled                   :boolean          not null
#  fcm_token                 :text
#  fcm_token_not_found       :boolean          default(FALSE)
#  gps_adid                  :text
#  idfa                      :text
#  idfv                      :text
#  imei                      :text
#  installation_uid          :text             not null
#  keep_service_alive        :boolean          default(TRUE)
#  language                  :integer          not null
#  last_opened_at            :datetime         not null
#  last_opened_ip            :inet             not null
#  mac                       :text
#  os                        :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :uuid
#  android_id                :text
#  app_version_id            :bigint
#  auth_id                   :text             not null
#
# Indexes
#
#  index_devices_on_account_id            (account_id)
#  index_devices_on_app_version_id        (app_version_id)
#  index_rider_devices_on_app_version_id  (app_version_id)
#  index_rider_devices_on_auth_id         (auth_id) UNIQUE
#

FactoryBot.define do
  factory :device, class: Devices::Device do
    # installation_id "966ebfa19-e9e2-4422-83c8-e7a81e12c058f133d70ad059e28e"
    device_type { 1 }
    # app_name "Test App"
    # app_version 1.0
    # language "en"
    # os "Test OS"
    # mac ""
    # imei ""
    # android_id ""
    # build_number 1
    # device_manufacturer "Manufacturer"
    # device_model "SM-G950Ff"
  end
end
