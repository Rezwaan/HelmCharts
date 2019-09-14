class Tags::TagService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    tag = Tags::Tag.new(attributes)

    if tag.save
      return create_dto(tag)
    else
      return tag.errors
    end
  end

  def update(tag_id:, attributes:)
    tag = Tags::Tag.find_by(id: tag_id)

    if tag.update(attributes)
      return create_dto(tag)
    else
      return tag.errors
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    tags = Tags::Tag.all
    tags = tags.by_id(criteria[:id]) if criteria[:id].present?
    tags = tags.by_name(criteria[:name]) if criteria[:name].present?
    tags = tags.order(sort_by => sort_direction) if sort_by

    tags = tags.includes(:translations)

    paginated_dtos(collection: tags, page: page, per_page: per_page) do |tag|
      create_dto(tag)
    end
  end

  def fetch(id)
    tag = Tags::Tag.where(id: id).first
    return nil unless tag
    create_dto(tag)
  end

  private

  def create_dto(tag)
    Tags::TagDTO.new({
      id: tag.id,
      name_en: tag.name_en,
      name_ar: tag.name_ar,
    })
  end
end
