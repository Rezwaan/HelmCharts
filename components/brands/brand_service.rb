class Brands::BrandService
  include Common::Helpers::PaginationHelper
  def find_or_create(platform_id:, attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    begin
      brand = Brands::Brand.where(platform_id: platform_id, backend_id: attributes[:backend_id]).first_or_initialize
      brand.name_en = attributes[:name_en] if attributes[:name_en].present?
      brand.name_ar = attributes[:name_ar] if attributes[:name_ar].present?
      brand.logo_url = attributes[:logo] if attributes[:logo].present?
      brand.cover_photo_url = attributes[:cover_photo_url] if attributes[:cover_photo_url].present?
      brand.country_id = attributes[:country_id] if attributes[:country_id].present?
      brand.company_id = attributes[:company_id] if attributes[:company_id].present?
      return create_dto(brand) if brand.save
      brand.errors
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def fetch_by_brand(brand:)
    brand_obj = Brands::Brand.find_by(id: brand[:id]) if brand[:id].present?
    create_dto(brand_obj)
  end

  def create(attributes:, category_ids: nil)
    brand = Brands::Brand.new(attributes)
    begin
      if brand.save
        data = add_categories(id: brand.id, category_ids: category_ids) if category_ids
        data ||= create_dto(brand)
        publish_pubsub(data: data, event: :brand_created, topic: :brand_created)
        return data
      end
    rescue ActiveRecord::RecordNotUnique
      brand.errors.add(:unique, message: "backend id must be unique")
    end

    brand.errors
  end

  def update(brand:, attributes:, category_ids: nil)
    begin
      if brand.update(attributes)
        data = add_categories(id: brand.id, category_ids: category_ids) if category_ids
        data ||= create_dto(brand)
        publish_pubsub(data: data, event: :brand_updated, topic: :brand_updated)
        return data
      end
    rescue ActiveRecord::RecordNotUnique
      brand.errors.add(:unique, message: "backend id must be unique")
    end

    brand.errors
  end

  def add_categories(id:, category_ids:)
    brand = Brands::Brand.find_by(id: id)
    return unless brand
    begin
      ids = Brands::Categories::BrandCategoryService.new.filter(criteria: {id: category_ids}).pluck(:id) if category_ids.present?
      ids ||= []
      already_added = brand.brand_brand_categories.where(brand_category_id: ids)
      (ids - already_added.map(&:brand_category_id)).each { |category_id| brand.brand_brand_categories.create(brand_category_id: category_id) }
      brand.brand_brand_categories.where("brand_category_id NOT IN (?)", ids + [0]).delete_all
      create_dto(brand)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def fetch(id:)
    brand = Brands::Brand.find_by(id: id)
    create_dto(brand)
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    brands = apply_scopes(criteria: criteria).includes(:translations, :brand_categories)
    brands = brands.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: brands, page: page, per_page: per_page) do |brand|
      create_dto(brand)
    end
  end

  def ids(criteria: {})
    apply_scopes(criteria: criteria).ids
  end

  def pluck(criteria: {}, field:)
    apply_scopes(criteria: criteria).pluck(field)
  end

  def create_dto(brand)
    return unless brand
    brand_categories = brand.brand_categories.map { |brand_category| Brands::Categories::BrandCategoryService.new.create_dto(brand_category) }
    Brands::BrandDTO.new(
      id: brand.id,
      name: brand.name,
      name_en: brand.name_en,
      name_ar: brand.name_ar,
      logo_url: brand.logo_url,
      cover_photo_url: brand.cover_photo_url,
      backend_id: brand.backend_id,
      brand_category: brand_categories.first,
      brand_categories: brand_categories,
      approved: brand.approved,
      contracted: brand.contracted,
      country_id: brand.country_id,
      company_id: brand.company_id
    )
  end

  private

  def apply_scopes(criteria: {})
    brands = Brands::Brand.where(nil)
    brands = brands.by_country_id(criteria[:country_id]) if criteria[:country_id].present?
    brands = brands.by_company_id(criteria[:company_id]) if criteria[:company_id].present?
    brands = brands.by_id(criteria[:id]) if criteria[:id].present?
    brands = brands.by_backend_id(criteria[:backend_id]) if criteria[:backend_id].present?
    brands = brands.by_similar_name(criteria[:similar_name]) if criteria[:similar_name].present?
    brands = brands.send(criteria[:status]) if criteria[:status].present?
    brands.includes(:translations, brand_category: :translations)
    brands
  end

  def publish_pubsub(data: {}, event:, topic:)
    Brands::PubSub::Publish.new.brand_publish(data: data, event: event, topic: topic)
  end
end
