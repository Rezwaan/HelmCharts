class ProductCatalog::ProductAttributeOptionService
  include Common::Helpers::PaginationHelper

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    product_attribute_options = ProductCatalog::ProductAttributeOption.all
    product_attribute_options = product_attribute_options.by_id(criteria[:id]) if criteria[:id].present?
    product_attribute_options = product_attribute_options.by_name(criteria[:name]) if criteria[:name].present?
    product_attribute_options = product_attribute_options.order(sort_by => sort_direction) if sort_by

    product_attribute_options = product_attribute_options.includes(:translations, :product_attribute)

    paginated_dtos(collection: product_attribute_options, page: page, per_page: per_page) do |product_attribute_option|
      create_dto(product_attribute_option)
    end
  end

  private

  def create_dto(product_attribute_option)
    ProductCatalog::ProductAttributeOptionDTO.new({
      id: product_attribute_option.id,
      display_name: "#{product_attribute_option.name} - #{product_attribute_option.product_attribute.name}",
    })
  end
end
