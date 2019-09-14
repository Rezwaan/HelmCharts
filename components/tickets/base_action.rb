module Tickets
  class BaseAction
    class << self
      def is_active_for_object?(object_class:, object_id:, ticket_type:)
        false
      end

      def data_for_object(ticket_type:)
        {}
      end

      def action_type
        raise "You must implement this method in #{self}"
      end

      def create_dto(object, ticket_type)
        Tickets::ActionDTO.new(
          data: data_for_object(ticket_type: ticket_type),
          action_type: action_type
        )
      end
    end
  end
end
