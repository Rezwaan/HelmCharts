class AppVersions::AppVersionService
  include Common::Helpers::PaginationHelper

  def find_or_create(attributes:)
    app_version = AppVersions::AppVersion.find_or_create_by(
      build_number: attributes[:build_number],
      device_type: attributes[:device_type],
      version_key: attributes[:version_key]
    )
    create_dto(app_version)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    app_versions = AppVersions::AppVersion.where(nil)
    app_versions = app_versions.by_id(criteria[:id]) if criteria[:id].present?
    app_versions = app_versions.by_build_number(criteria[:build_number]) if criteria[:build_number].present?
    app_versions = app_versions.by_device_type(criteria[:device_type]) if criteria[:device_type].present?
    app_versions = app_versions.by_version_key(criteria[:version_key]) if criteria[:version_key].present?
    app_versions = app_versions.by_update_action(criteria[:update_action]) if criteria[:update_action].present?
    app_versions = app_versions.by_search_key(criteria[:field_name], criteria[:query]) if criteria[:field_name].present? && criteria[:query].present?
    app_versions = app_versions.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: app_versions, page: page, per_page: per_page) do |app_version|
      create_dto(app_version)
    end
  end

  def searchable_fields
    AppVersions::AppVersion::SEARCHABLE_FIELDS
  end

  def fetch(id:)
    app_version = AppVersions::AppVersion.find_by(id: id)
    create_dto(app_version)
  end

  def update_action(id:, action:)
    app_version = AppVersions::AppVersion.find_by(id: id)
    return unless app_version
    app_version.update_attribute(:update_action, action)
    create_dto(app_version)
  end

  def bulk_update_action(id:, action:)
    app_versions = AppVersions::AppVersion.where(id: id)
    return unless app_versions
    app_versions.each do |app_version|
      app_version.update_attribute(:update_action, action)
    end
    paginated_dtos(collection: app_versions, page: 1, per_page: 200) do |app_version|
      create_dto(app_version)
    end
  end

  def enum_options
    options = {}
    AppVersions::AppVersion.defined_enums.keys.each do |key|
      options[key.pluralize] = AppVersions::AppVersion.send(key.pluralize).map { |k, v| {key: v, value: k} }
    end
    options
  end

  private

  def create_dto(app_version)
    return unless app_version
    secret = device_type_secrets(app_version.device_type.to_sym)
    AppVersions::AppVersionDTO.new(
      id: app_version.id,
      build_number: app_version.build_number,
      device_type: app_version.device_type,
      version_key: app_version.version_key,
      update_action: app_version.update_action,
      app_store_url: secret[:app_url],
      package_name: secret[:package_name]
    )
  end

  def secrets
    Rails.application.secrets.app_versions || {}
  end

  def device_type_secrets(device_type)
    secrets[device_type] || {}
  end
end
