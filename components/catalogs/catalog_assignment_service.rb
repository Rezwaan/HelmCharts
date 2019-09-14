class Catalogs::CatalogAssignmentService
  include Common::Helpers::PaginationHelper

  def related_to(related_to_id:, related_to_type:)
    Catalogs::CatalogAssignment.find_by(related_to_id: related_to_id, related_to_type: related_to_type)
  end

  def update_assignments(id:, assignments:)
    existing_assignments = Catalogs::CatalogAssignment.where(catalog_id: id).to_a
    to_add_assignments = assignments_diff(assignments, existing_assignments)
    to_remove_assignments = assignments_diff(existing_assignments, assignments)
    Catalogs::CatalogAssignment.where(id: to_remove_assignments.pluck(:id)).destroy_all

    to_add_assignments.each do |assignment|
      assignment = Catalogs::CatalogAssignment.where(related_to_type: assignment[:related_to_type], related_to_id: assignment[:related_to_id]).first_or_initialize
      # @TODO: Validate that the catalog belongs to the same same brand
      assignment.catalog_id = id
      assignment.save
    end

    publish_assigned(assignments: to_add_assignments, catalog_id: id)
    Catalogs::CatalogAssignment.where(catalog_id: id).to_a
  end

  def publish_assigned(assignments:, catalog_id:)
    brand_ids = fetch_ids_for(type: "Brands::Brand", assignments: assignments)
    store_ids = fetch_ids_for(type: "Stores::Store", assignments: assignments)

    return if brand_ids.blank? && store_ids.blank?

    event_data = {
      catalog_id: catalog_id,
      brand_primary_ids: brand_ids,
      store_primary_ids: store_ids,
    }

    Catalogs::PubSub::Publish.new.catalog_assigned(data: event_data, update: :assigned)
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    catalog_assignments = Catalogs::CatalogAssignment.where(nil)
    catalog_assignments = catalog_assignments.where(related_to_type: criteria[:related_to_type]) if criteria[:related_to_type].present?
    catalog_assignments = catalog_assignments.where(related_to_id: criteria[:related_to_id]) if criteria[:related_to_id].present?
    catalog_assignments = catalog_assignments.where(catalog_id: criteria[:catalog_id]) if criteria[:catalog_id].present?
    catalog_assignments = catalog_assignments.order(sort_by => sort_direction) if sort_by

    paginated_dtos(collection: catalog_assignments, page: page, per_page: per_page) do |catalog_assignment|
      create_dto(catalog_assignment)
    end
  end

  def assignments_count_type(catalog_id:)
    assignment_counts = Catalogs::CatalogAssignment.where(catalog_id: catalog_id).group(:related_to_type).count

    {
      store_assignments: assignment_counts["Stores::Store"] || 0,
      brand_assignments: assignment_counts["Brands::Brand"] || 0,
    }
  end

  def destroy_by_store(store_id:)
    Catalogs::CatalogAssignment.where(related_to_type: "Stores::Store", related_to_id: store_id).destroy_all
  end

  private

  def assignments_diff(collection1, collection2)
    collection1.reject do |assignment1|
      collection2.any? do |assignment2|
        assignment1[:resource_to_type] == assignment2[:related_to_type] && assignment1[:related_to_id] == assignment2[:related_to_id]
      end
    end
  end

  def fetch_ids_for(type:, assignments:)
    assignments.map { |assignment| assignment[:related_to_id] if assignment[:related_to_type] == type }.compact
  end

  def create_dto(catalog_assignment)
    ::Catalogs::CatalogAssignmentDTO.new({
      id: catalog_assignment.id,
      catalog_id: catalog_assignment.catalog_id,
      related_to_type: catalog_assignment.related_to_type,
      related_to_id: catalog_assignment.related_to_id,
    })
  end
end
