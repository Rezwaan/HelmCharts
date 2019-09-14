class ProductCatalog::ProductAttributeService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    product_attribute = ProductCatalog::ProductAttribute.new(attributes)

    if product_attribute.save
      return create_dto(product_attribute)
    else
      return product_attribute.errors
    end
  end

  def update(product_attribute_id:, attributes:)
    product_attribute = ProductCatalog::ProductAttribute.find_by(id: product_attribute_id)

    if product_attribute.update(attributes)
      return create_dto(product_attribute)
    else
      return product_attribute.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    product_attributes = ProductCatalog::ProductAttribute.all
    product_attributes = product_attributes.by_id(criteria[:id]) if criteria[:id].present?
    product_attributes = product_attributes.by_name(criteria[:name]) if criteria[:name].present?
    product_attributes = product_attributes.order(sort_by => sort_direction) if sort_by

    product_attributes = product_attributes.includes(:translations)

    paginated_dtos(collection: product_attributes, page: page, per_page: per_page) do |product_attribute|
      create_dto(product_attribute)
    end
  end

  def fetch(id)
    product_attribute = ProductCatalog::ProductAttribute.where(id: id).first
    return nil unless product_attribute
    create_dto(product_attribute)
  end

  private

  def create_dto(product_attribute)
    ProductCatalog::ProductAttributeDTO.new({
      id: product_attribute.id,
      name_en: product_attribute.name_en,
      name_ar: product_attribute.name_ar,
      options: product_attribute.options.map do |option|
        {
          id: option.id,
          name_en: option.name_en,
          name_ar: option.name_ar,
          created_at: option.created_at,
          updated_at: option.updated_at,
        }
      end,
      created_at: product_attribute.created_at,
      updated_at: product_attribute.updated_at,
    })
  end
end
