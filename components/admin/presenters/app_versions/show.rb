class Admin::Presenters::AppVersions::Show
  def initialize(dto:)
    @app_version = dto
  end

  def present
    {
      "id": @app_version.id,
      "build_number": @app_version.build_number,
      "device_type": @app_version.device_type,
      "version_key": @app_version.version_key,
      "update_action": @app_version.update_action,
      "app_store_url": @app_version.app_store_url,
      "package_name": @app_version.package_name,
    }
  end
end
