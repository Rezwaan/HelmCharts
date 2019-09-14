class ProductCatalog::ProductService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    product = ProductCatalog::Product.new(attributes)

    if product.save
      return create_dto(product)
    else
      return product.errors
    end
  end

  def update(product_id:, attributes:)
    product = ProductCatalog::Product.find_by(id: product_id)

    if product.update(attributes)
      return create_dto(product)
    else
      return product.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    products = ProductCatalog::Product.all
    products = products.by_id(criteria[:id]) if criteria[:id].present?
    products = products.by_name(criteria[:name]) if criteria[:name].present?
    products = products.by_prototype_name(criteria[:prototype_name]) if criteria[:prototype_name].present?
    products = products.by_manufacturer_name(criteria[:manufacturer_name]) if criteria[:manufacturer_name].present?
    products = products.order(sort_by => sort_direction) if sort_by

    products = products.includes(:translations, :prototype, :manufacturer)

    paginated_dtos(collection: products, page: page, per_page: per_page) do |product|
      create_dto(product)
    end
  end

  def fetch(id)
    product = ProductCatalog::Product.where(id: id).first
    return nil unless product
    create_dto(product)
  end

  private

  def create_dto(product)
    ProductCatalog::ProductDTO.new({
      id: product.id,
      name_en: product.name_en,
      name_ar: product.name_ar,
      description_en: product.description_en,
      description_ar: product.description_ar,
      default_price: product.default_price,
      prototype: product.prototype,
      manufacturer: product.manufacturer,
    })
  end
end
