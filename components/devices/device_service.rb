class Devices::DeviceService
  # Registers new device
  #
  # @param [Hash] device attributes. installation_uid, device_type, language, last_opened_ip, created_ip are
  # required
  #
  # @return nil if installation_uid and device_type is not present in attributes
  # @return [ActiveMode::Errors] if validation failed
  # @return [Devices::DeviceDTO]
  def register(attributes: {})
    return nil unless attributes[:installation_uid].present? && attributes[:device_type].present?

    device = ::Devices::Device.find_or_initialize_by(installation_uid: attributes[:installation_uid],
                                                     device_type: attributes[:device_type])
    if device.new_record?
      auth_id = SecureRandom.uuid.remove(/\-/) + SecureRandom.uuid.remove(/\-/)
      auth_key = SecureRandom.uuid.remove(/\-/) + SecureRandom.uuid.remove(/\-/)

      device.assign_attributes(auth_id: auth_id, auth_key: auth_key)
    end

    device.enabled = true
    device.last_opened_at = Time.now

    permitted_attributes = attributes.select { |key, _| fillable_attributes.include?(key.to_sym) }
    permitted_attributes[:language] = get_language(param_lang: permitted_attributes[:language], existing_lang: nil)

    device.assign_attributes(permitted_attributes)
    app_version = AppVersions::AppVersionService.new.find_or_create(attributes: {build_number: attributes[:build_number], device_type: device.device_type, version_key: attributes[:app_version]})
    device.app_version_id = app_version&.id

    if device.save
      dto = create_dto(device, app_version)
      dto[:auth_id] = device.auth_id
      dto[:auth_key] = device.auth_key
      return dto
    end

    device.errors
  end

  # Fetch and return a list of devices from Database
  #
  # @params [Hash]    criteria
  # @params [Integer] offset
  # @params [Integer] limit
  # @params [Symbol]  sort_by
  # @params [Symbol]  sort_direction
  #
  # @return [Array(Devices::DeviceDTO)] an array of devices that match the critieria
  def filter(criteria: {}, offset: 0, limit: 20, sort_by: :id, sort_direction: "asc")
    devices = Devices::Device.offset(offset).limit(limit)

    devices = devices.by_id(criteria[:id]) if criteria[:id].present?
    devices = devices.by_account_id(criteria[:account_id]) if criteria[:account_id].present?
    devices = devices.by_auth_id(criteria[:auth_id]) if criteria[:auth_id].present?
    devices = devices.by_auth_key(criteria[:auth_key]) if criteria[:auth_key].present?
    devices = devices.by_installation_id(criteria[:installation_id]) if criteria[:installation_id].present?

    if sort_by
      devices = devices.order(sort_by => sort_direction)
    end

    devices.map { |device| create_dto(device) }
  end

  def get_credentials(auth_id:)
    device = Devices::Device.find_by(auth_id: auth_id)
    if device
      return {
        id: device.auth_id,
        key: device.auth_key,
        algorithm: "sha256",
      }
    end

    nil
  end

  # Update an existing device
  #
  # @params [String] id of the device
  # @params [Hash] attributes new attributes to assign
  #
  # @return [Devices::DeviceDTO] if successfully updated
  # @return [ActiveModel::Errors] if failed
  # @return [nil] if not found
  def update(id:, attributes:, check_version: false)
    device = Devices::Device.find_by(id: id)

    return nil unless device

    permitted_attributes = attributes.select { |key, _| fillable_attributes.include?(key.to_sym) }
    permitted_attributes[:language] = get_language(param_lang: permitted_attributes[:language], existing_lang: device.language)

    device.assign_attributes(permitted_attributes)
    app_version = nil
    if check_version && attributes[:build_number].present?
      app_version = AppVersions::AppVersionService.new.find_or_create(attributes: {build_number: attributes[:build_number], device_type: device.device_type, version_key: attributes[:app_version]})
      device.app_version_id = app_version&.id
    end
    app_version ||= AppVersions::AppVersionService.new.fetch(id: device.app_version_id) if device.app_version_id.present?

    if device.save
      create_dto(device, app_version)
    else
      device.errors
    end
  end

  def device_opened(id:, ip:)
    device = Devices::Device.where(id: id).first
    if device.last_opened_at < Time.now - 12.hours
      Devices::DeviceService.new.update(id: id, attributes: {last_opened_at: Time.now, last_opened_ip: ip})
    end
  end

  def increment_counter(id:)
    Devices::Device.increment_counter(:device_usage, id) if Rails.application.secrets.app_versions[:device_usage_enabled]
  end

  def account_id_cleanup(account_id:)
    devices = filter(criteria: {account_id: account_id})
    if devices.present?
      devices.each do |device|
        update(id: device.id, attributes: {account_id: nil})
      end
    end
  end

  def fetch(auth_id:, auth_key:)
    device = Devices::Device.find_by(auth_id: auth_id, auth_key: auth_key)

    return create_dto(device) if device
    nil
  end

  def fetch_by_id(id:)
    device = Devices::Device.find(id)
    return create_dto(device) if device
    nil
  end

  def fetch_by_account_id(account_id:)
    return if account_id.blank?
    device = Devices::Device.by_enabled(true).by_account_id(account_id).order(last_opened_at: :desc).first
    return create_dto(device) if device
    nil
  end

  def notifiable_devices(account_ids:, device_type: nil, apn_only: false)
    return [] unless account_ids.present?
    criteria = {account_id: account_ids, enabled: true, enable_notifications: true, device_type: device_type}
    if apn_only
      criteria[:apn_token_present] = true
    else
      criteria[:fcm_token_present] = true
      criteria[:fcm_token_not_found] = false
    end
    filter(criteria: criteria, sort_by: :last_opened_at, sort_direction: :desc)
  end

  def mark_fcm_invalid(id:)
    user_device = Devices::Device.find_by(id: id)
    return unless user_device
    user_device.update_attribute(:fcm_token_not_found, true)
    create_dto(user_device)
  end

  private

  def fillable_attributes
    [
      :os,
      :idfa,
      :idfv,
      :mac,
      :android_id,
      :gps_adid,
      :imei,
      :fcm_token,
      :apn_token,
      :account_id,
      :enable_notifications,
      :current_lonlat,
      :current_location_accuracy,
      :language,
      :device_manufacturer,
      :device_model,
      :keep_service_alive,
      :draw_overlay,
      :last_opened_at,
      :last_opened_ip,
      :created_ip,
      :payment_preference,
    ]
  end

  def create_dto(device, app_version = nil)
    Devices::DeviceDTO.new(
      id: device.id,
      enabled: device.enabled,
      device_type: device.device_type,
      os: device.os,
      app_version: app_version&.version_key,
      idfa: device.idfa,
      idfv: device.idfv,
      mac: device.mac,
      android_id: device.android_id,
      gps_adid: device.gps_adid,
      imei: device.imei,
      fcm_token: device.fcm_token,
      apn_token: device.apn_token,
      enable_notifications: device.enable_notifications,
      current_lonlat: device.current_lonlat,
      current_location_accuracy: device.current_location_accuracy,
      language: device.language,
      last_opened_at: device.last_opened_at,
      last_opened_ip: device.last_opened_ip.to_s,
      created_ip: device.created_ip.to_s,
      account_id: device.account_id,
      device_manufacturer: device.device_manufacturer,
      device_model: device.device_model,
      app_version_id: device.app_version_id,
      device_usage: device.device_usage,
      keep_service_alive: device.keep_service_alive,
      created_at: device.created_at,
      updated_at: device.updated_at,
      build_number: app_version&.build_number
    )
  end

  def get_language(param_lang:, existing_lang:)
    if param_lang.blank?
      existing_lang.present? ? existing_lang : "en"
    else
      param_lang.to_s.in?(Devices::Device.languages.keys.map(&:to_s)) ? param_lang : "en"
    end
  end
end
