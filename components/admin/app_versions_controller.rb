class Admin::AppVersionsController < Admin::ApplicationController
  def index
    authorize(AppVersions::AppVersion)

    app_version_dtos = AppVersions::AppVersionService.new.filter(
      criteria: params.dig(:criteria) || {},
      page: @page,
      per_page: @per_page,
      sort_by: @sort_by || :created_at,
      sort_direction: @sort_direction,
    )

    render json: {
      status: true,
      total_records: app_version_dtos.total_count,
      total_pages: app_version_dtos.total_pages,
      data: app_version_dtos.map { |app_version_dto|
        Admin::Presenters::AppVersions::Show.new(dto: app_version_dto).present
      },
    }
  end

  def show
    authorize(AppVersions::AppVersion)

    criteria = {id: params[:id]}
    app_version_dto = AppVersions::AppVersionService.new.filter(criteria: criteria, per_page: 1).first

    return render json: {status: false, errors: "Not found"}, status: :not_found if app_version_dto

    render json: {status: true, data: Admin::Presenters::AppVersions::Show.new(dto: app_version_dto).present}
  end

  def search
    authorize(AppVersions::AppVersion)

    criteria = {field_name: params[:field_name], query: params[:query]}
    app_version_dtos = AppVersions::AppVersionService.new.filter(
      criteria: criteria,
      page: @page,
      per_page: @per_page,
      sort_by: @sort_by || :created_at,
      sort_direction: @sort_direction,
    )

    render json: {
      status: true,
      total_records: app_version_dtos.total_count,
      total_pages: app_version_dtos.total_pages,
      data: app_version_dtos.map { |app_version_dto|
        Admin::Presenters::AppVersions::Show.new(dto: app_version_dto).present
      },
    }
  end

  def update
    authorize(AppVersions::AppVersion)

    criteria = {id: params[:id]}
    app_version = AppVersions::AppVersionService.new.filter(criteria: criteria, per_page: 1).first
    app_version_dto = AppVersions::AppVersionService.new.update_action(id: app_version.id, action: params[:update_action]) if app_version
    if app_version_dto
      render json: {status: true, data: Admin::Presenters::AppVersions::Show.new(dto: app_version_dto).present}
    else
      render json: {status: false, errors: "Not found"}, status: :not_found
    end
  end

  def bulk_update
    criteria = {id: params[:id]}
    app_versions = AppVersions::AppVersionService.new.filter(criteria: criteria)
    app_version_dtos = AppVersions::AppVersionService.new.bulk_update_action(id: app_versions.map(&:id), action: params[:update_action]) if app_versions

    return render json: {status: false, errors: "Not found"}, status: :not_found unless app_version_dtos

    render json: {
      status: true,
      total_records: app_version_dtos.total_count,
      total_pages: app_version_dtos.total_pages,
      data: app_version_dtos.map { |app_version_dto|
        Admin::Presenters::AppVersions::Show.new(dto: app_version_dto).present
      },
    }
  end

  def enum_options
    options = AppVersions::AppVersionService.new.enum_options

    return render json: {status: false, errors: "Not found"}, status: :not_found unless options

    render json: {status: true, data: options}
  end
end
