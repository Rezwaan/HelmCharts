module Tickets
  module Actions
    class CreateTicketAction < Tickets::BaseAction
      class << self
        def is_active_for_object?(object_class:, object_id:, ticket_type:)
          !Tickets::TicketService.new.ticket_already_created(
            related_to_type: object_class,
            related_to_id: object_id,
            ticket_type: Tickets::Ticket.ticket_types[ticket_type.title]
          )
        end

        def data_for_object(ticket_type:)
          {
            ticket_type_code: Ticket.ticket_types[ticket_type.title],
          }
        end

        def action_type
          "create_ticket"
        end
      end
    end
  end
end
