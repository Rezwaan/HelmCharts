module Integrations
  class IntegrationOrderService
    include Common::Helpers::PaginationHelper

    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
      integration_orders = IntegrationOrder.where(nil)
      integration_orders = integration_orders.by_id(criteria[:id]) if criteria[:id].present?
      integration_orders = integration_orders.where(order_id: criteria[:order_id]) if criteria[:order_id].present?
      integration_orders = integration_orders.where(external_reference: criteria[:external_reference]) if criteria[:external_reference].present?
      integration_orders = integration_orders.order(sort_by => sort_direction) if sort_by

      paginated_dtos(collection: integration_orders, page: page, per_page: per_page) do |integration_order|
        create_dto(integration_order)
      end
    end

    def fetch(id)
      integration_order = IntegrationOrder.all.where(id: id).first
      return nil unless integration_order

      create_dto(integration_order)
    end

    private

    def create_dto(integration_order)
      IntegrationOrderDTO.new(
        {
          id: integration_order.id,
          external_reference: integration_order.external_reference,
          order_id: integration_order.order_id,
        }
      )
    end
  end
end
