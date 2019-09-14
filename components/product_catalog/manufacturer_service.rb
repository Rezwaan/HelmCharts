class ProductCatalog::ManufacturerService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    manufacturer = ProductCatalog::Manufacturer.new(attributes)

    if manufacturer.save
      return create_dto(manufacturer)
    else
      return manufacturer.errors
    end
  end

  def update(manufacturer_id:, attributes:)
    manufacturer = ProductCatalog::Manufacturer.find_by(id: manufacturer_id)

    if manufacturer.update(attributes)
      return create_dto(manufacturer)
    else
      return manufacturer.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    manufacturers = ProductCatalog::Manufacturer.all
    manufacturers = manufacturers.by_id(criteria[:id]) if criteria[:id].present?
    manufacturers = manufacturers.by_name(criteria[:name]) if criteria[:name].present?
    manufacturers = manufacturers.order(sort_by => sort_direction) if sort_by

    manufacturers = manufacturers.includes(:translations)

    paginated_dtos(collection: manufacturers, page: page, per_page: per_page) do |manufacturer|
      create_dto(manufacturer)
    end
  end

  def fetch(id)
    manufacturer = ProductCatalog::Manufacturer.where(id: id).first
    return nil unless manufacturer
    create_dto(manufacturer)
  end

  private

  def create_dto(manufacturer)
    ProductCatalog::ManufacturerDTO.new({
      id: manufacturer.id,
      name_en: manufacturer.name_en,
      name_ar: manufacturer.name_ar,
    })
  end
end
