module Common::Helpers::PaginationHelper
  def paginated_dtos(collection:, page:, per_page:, paginate_info: true)
    if per_page.to_i.positive?
      collection = paginated_collection(
        collection: collection,
        page: page,
        per_page: per_page,
        paginate_info: paginate_info,
      )
    end

    create_dtos(collection.map { |record| yield(record) }.compact, collection)
  end

  private

  def paginated_collection(collection:, page:, per_page:, paginate_info: true)
    if collection.is_a? Array
      Kaminari.paginate_array(collection).page(page).per(per_page)
    elsif paginate_info
      collection.page(page).per(per_page)
    else
      collection.limit(per_page).offset((page <= 0 ? 0 : (page - 1)) * per_page.to_i)
    end
  end

  def create_dtos(dtos, model = nil)
    dto_collection = DTOCollection.new(dtos)

    if model
      dto_collection.total_count = model.total_count if model.respond_to?(:total_count)

      dto_collection.total_pages = model.total_pages if model.respond_to?(:total_pages)
    end

    dto_collection
  end
end
