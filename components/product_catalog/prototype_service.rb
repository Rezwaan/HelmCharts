class ProductCatalog::PrototypeService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    prototype = ProductCatalog::Prototype.new(attributes)

    if prototype.save
      return create_dto(prototype)
    else
      return prototype.errors
    end
  end

  def update(prototype_id:, attributes:)
    prototype = ProductCatalog::Prototype.find_by(id: prototype_id)

    if prototype.update(attributes)
      return create_dto(prototype)
    else
      return prototype.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    prototypes = ProductCatalog::Prototype.all
    prototypes = prototypes.by_id(criteria[:id]) if criteria[:id].present?
    prototypes = prototypes.by_name(criteria[:name]) if criteria[:name].present?
    prototypes = prototypes.order(sort_by => sort_direction) if sort_by

    prototypes = prototypes.includes(:translations)

    paginated_dtos(collection: prototypes, page: page, per_page: per_page) do |prototype|
      create_dto(prototype)
    end
  end

  def fetch(id)
    prototype = ProductCatalog::Prototype.where(id: id).first
    return nil unless prototype
    create_dto(prototype)
  end

  private

  def create_dto(prototype)
    ProductCatalog::PrototypeDTO.new({
      id: prototype.id,
      name_en: prototype.name_en,
      name_ar: prototype.name_ar,
      product_attribute_ids: prototype.product_attribute_ids,
    })
  end
end
