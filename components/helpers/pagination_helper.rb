# frozen_string_literal: true

module Helpers::PaginationHelper
  def paginated_dtos(collection:, page:, per_page:, light_dto: false, pagination_meta: true)
    collection = paginated_collection(collection: collection, page: page, per_page: per_page) if per_page.to_i.positive?
    create_dtos(collection.map { |record| yield(record, light: light_dto) }.compact, pagination_meta, collection)
  end

  private

  def paginated_collection(collection:, page: 1, per_page: 50)
    if collection.is_a? Array
      Kaminari.paginate_array(collection).page(page).per(per_page)
    else
      collection.page(page).per(per_page)
    end
  end

  def create_dtos(dtos, pagination_meta, active_record_relation = nil)
    dto_collection = DTOCollection.new(dtos)
    if active_record_relation && pagination_meta
      dto_collection.total_count = active_record_relation.total_count if active_record_relation.respond_to?(:total_count)
      dto_collection.total_pages = active_record_relation.total_pages if active_record_relation.respond_to?(:total_pages)
    end
    dto_collection
  end
end
