class Brands::Categories::BrandCategoryService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    category = Brands::Categories::BrandCategory.new(attributes)
    return create_dto(category) if category.save
    category.errors
  end

  def update(id:, attributes:)
    category = Brands::Categories::BrandCategory.find_by(id: id)
    return nil unless category
    category.assign_attributes(attributes)
    return create_dto(category) if category.save
    category.errors
  end

  def fetch(id:)
    category = Brands::Categories::BrandCategory.find_by_id(id)
    create_dto(category)
  end

  def fetch_by_key(key:)
    category = Brands::Categories::BrandCategory.find_by_key(key)
    create_dto(category)
  end

  def apply_scopes(criteria: {})
    categories = Brands::Categories::BrandCategory.where(nil)
    categories = categories.where(id: criteria[:id]) if criteria[:id].present?
    categories = categories.where(key: criteria[:key]) if criteria[:key].present?
    categories
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc", light: false)
    categories = apply_scopes(criteria: criteria).includes(:translations)
    categories = categories.order(sort_by => sort_direction) if sort_by
    paginated_dtos(collection: categories, page: page, per_page: per_page) do |category|
      create_dto(category)
    end
  end

  def create_dto(category)
    return nil unless category

    Brands::Categories::BrandCategoryDTO.new(
      id: category.id,
      name_ar: category.name_ar,
      name_en: category.name_en,
      plural_name_ar: category.plural_name_ar,
      plural_name_en: category.plural_name_en,
      name: category.name,
      plural_name: category.plural_name,
      key: category.key,
      plural_key: category.key.pluralize
    )
  end
end
