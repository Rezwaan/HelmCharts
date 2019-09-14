module Integrations
  class IntegrationHostService
    include Common::Helpers::PaginationHelper

    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
      integration_hosts = IntegrationHost.all
      integration_hosts = integration_hosts.by_id(criteria[:id]) if criteria[:id].present?
      integration_hosts = integration_hosts.where(name: criteria[:name]) if criteria[:name].present?
      integration_hosts = integration_hosts.where(enabled: criteria[:enabled]) if criteria[:enabled].present?
      integration_hosts = integration_hosts.order(sort_by => sort_direction) if sort_by

      paginated_dtos(collection: integration_hosts, page: page, per_page: per_page) do |integration_host|
        create_dto(integration_host)
      end
    end

    def update(integration_host_id:, attributes:)
      integration_host = IntegrationHost.find_by(id: integration_host_id)

      if integration_host.update(attributes)
        return create_dto(integration_host)
      else
        return integration_host.errors
      end
    end

    def create(attributes:)
      integration_host = IntegrationHost.new(attributes)

      return integration_host.errors unless integration_host.save

      create_dto(integration_host)
    end

    def fetch(id)
      integration_host = IntegrationHost.all.where(id: id).first
      return nil unless integration_host

      create_dto(integration_host)
    end

    def integration_types
      IntegrationHost.integration_types
    end

    private

    def create_dto(integration_host)
      IntegrationHostDTO.new(
        {
          id: integration_host.id,
          name: integration_host.name,
          integration_type: integration_host.integration_type,
          config: integration_host.config,
          enabled: integration_host.enabled,
        }
      )
    end
  end
end
