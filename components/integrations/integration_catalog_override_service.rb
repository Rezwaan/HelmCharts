module Integrations
  module IntegrationCatalogOverrideService
    include Common::Helpers::PaginationHelper
    extend self

    def filter(integration_catalog_id:, criteria: {}, page: 1, per_page: 50, sort_by: :item_type, sort_direction: "asc")
      integration_catalog = Integrations::IntegrationCatalog.find(integration_catalog_id)
      overrides = integration_catalog.overrides

      if sort_by
        overrides = integration_catalog.overrides.order(sort_by => sort_direction)
      end

      paginated_dtos(collection: overrides, page: page, per_page: per_page) { |override|
        create_dto(override)
      }
    end

    def fetch(id)
      override = Integrations::IntegrationCatalogOverride.find(id)

      create_dto(override)
    end

    def fetch_overrides(integration_catalog_id:)
      integration_catalog = Integrations::IntegrationCatalog.find(integration_catalog_id)

      integration_catalog.overrides.map { |o| create_dto(o) }
    end

    # Fetches all the overrides for an integration catalog and applies them to a
    # Dome catalog.
    #
    # @param integration_catalog_id [String] The ID (uuid) of the integration catalog to apply overrides to
    # @param catalog [Hash] The catalog to apply the overrides to. This is an
    #   integration catalog that has been serialized to the
    #   Dome/Firestore format.
    # @return [HashWithIndifferentAccess] The dome_catalog but with the overrides applied to the catalog.
    def apply_overrides(integration_catalog_id:, catalog:)
      overrides = fetch_overrides(integration_catalog_id: integration_catalog_id)

      return catalog unless overrides

      catalog = catalog.with_indifferent_access

      overrides.each  do |override|

        # The item ID in the catalog may be an integer or a string depending on
        # how the serializer did it, we'll try both and skip if neither worked
        string_entry_path = [override.item_type.to_sym, override.item_id.to_s]
        integer_entry_path = [override.item_type.to_sym, override.item_id.to_i]

        catalog_entry = catalog.dig(*string_entry_path) || catalog.dig(*integer_entry_path)

        next unless catalog_entry

        catalog_entry.merge!(override.properties)
      end

      catalog
    end

    private

    def create_dto(override)
      IntegrationCatalogOverrideDTO.new(
        {
          id: override.id,
          integration_catalog_id: override.integration_catalog_id,
          item_type: override.item_type,
          item_id: override.item_id,
          properties: override.properties,
          created_at: override.created_at,
          updated_at: override.updated_at,
        }
      )
    end
  end
end
