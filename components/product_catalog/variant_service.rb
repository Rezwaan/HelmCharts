class ProductCatalog::VariantService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    variant = ProductCatalog::Variant.new(attributes)

    if variant.save
      return create_dto(variant)
    end

    variant.errors
  end

  def update(variant_id:, attributes:)
    variant = ProductCatalog::Variant.find_by(id: variant_id)

    if variant.update(attributes)
      return create_dto(variant)
    end

    variant.errors
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    variants = ProductCatalog::Variant.all
    variants = variants.by_id(criteria[:id]) if criteria[:id].present?
    variants = variants.by_name(criteria[:name]) if criteria[:name].present?
    variants = variants.order(sort_by => sort_direction) if sort_by

    variants = variants.includes(:translations, :product, :product_attribute_options)

    paginated_dtos(collection: variants, page: page, per_page: per_page) do |variant|
      create_dto(variant)
    end
  end

  def fetch(id)
    variant = ProductCatalog::Variant.where(id: id).first
    return nil unless variant

    create_dto(variant)
  end

  private

  def create_dto(variant)
    ProductCatalog::VariantDTO.new({
      id: variant.id,
      name_en: variant.name_en,
      name_ar: variant.name_ar,
      sku: variant.sku,
      price: variant.price,
      product: variant.product,
      product_attribute_option_ids: variant.product_attribute_option_ids,
    })
  end
end
