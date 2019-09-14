class Platforms::PlatformService
  include Helpers::PaginationHelper
  def find_or_create(attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    begin
      platform = Platforms::Platform.where(backend_id: attributes[:backend_id]).first_or_initialize
      platform.name_en = attributes[:name_en] if attributes[:name_en].present?
      platform.name_ar = attributes[:name_ar] if attributes[:name_ar].present?
      platform.logo_url = attributes[:logo] if attributes[:logo].present?
      return create_dto(platform) if platform.save
      platform.errors
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def update(id:, attributes: {})
    platform = Platforms::Platform.find_by(id: id)
    return unless platform
    platform.assign_attributes(attributes)

    if platform.save
      create_dto(platform)
    else
      platform.errors
    end
  end

  def first_or_by(id = nil)
    platform = if id
      Platforms::Platform.find_by(id: id)
    else
      Platforms::Platform.first
    end

    platform&.id
  end

  def fetch(id:)
    platform = Platforms::Platform.find_by(id: id)
    create_dto(platform)
  end

  def fetch_by_backend_id(backend_id:)
    platform = Platforms::Platform.find_by(backend_id: backend_id)
    create_dto(platform)
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "desc")
    platforms = Platforms::Platform.where(nil)
    platforms = platforms.by_id(criteria[:id]) if criteria[:id].present?
    platforms = platforms.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: platforms, page: page, per_page: per_page) do |platform|
      create_dto(platform)
    end
  end

  def create_dto(platform)
    return unless platform
    ::Platforms::PlatformDTO.new(
      id: platform.id,
      name: platform.name,
      name_en: platform.name_en,
      name_ar: platform.name_ar,
      backend_id: platform.backend_id,
      logo_url: platform.logo_url
    )
  end
end
