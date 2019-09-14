module Tickets
  module Core
    class << self
      def creatable_ticket_types_enum
        @creatable_ticket_types_enum_storage ||= {}
      end

      def all_ticket_types_enum
        @all_ticket_types_enum_storage ||= {}
      end

      def all_ticket_types
        @ticket_types_storage ||= {}
      end

      def add_ticket_type(ticket_type, code)
        all_ticket_types[code] = ticket_type
        all_ticket_types_enum[ticket_type.title] = code
        ticket_type.code = code
        if ticket_type.type == TicketType::TicketTypeKinds::CREATABLE
          creatable_ticket_types_enum[ticket_type.title] = code
        end
      end

      def tree_for_object(object, creator)
        tree = []
        child_ticket_type_kinds = [Tickets::TicketType::TicketTypeKinds::CREATABLE, Tickets::TicketType::TicketTypeKinds::DECLERATION]
        Tickets::Core.all_ticket_types.values.compact.select { |ticket_type| child_ticket_type_kinds.include?(ticket_type.type) }.each do |ticket_type|
          if ticket_type.general_is_applicable_for?(object, creator)
            parent_ticket = Tickets::Core.all_ticket_types[ticket_type.parent_code]
            unless tree.include?(parent_ticket)
              tree.push parent_ticket
            end
            tree.push ticket_type
          end
        end
        tree = [Tickets::TicketTypes::Root] + tree if tree.any? && tree.exclude?(Tickets::TicketTypes::Root)

        tree.map { |ticket_type| ticket_type.create_dto(object) }
      end
    end

    # Root ticket_type
    add_ticket_type Tickets::TicketTypes::Root, 0
    add_ticket_type Tickets::TicketTypes::Technical, 2
    add_ticket_type Tickets::TicketTypes::Account, 21
    add_ticket_type Tickets::TicketTypes::Application, 22
    add_ticket_type Tickets::TicketTypes::OtherTechnicalIssue, 23
    add_ticket_type Tickets::TicketTypes::FinancialIssue, 3
    add_ticket_type Tickets::TicketTypes::OrderAmount, 31
    add_ticket_type Tickets::TicketTypes::Payment, 32
    add_ticket_type Tickets::TicketTypes::OtherFinancialIssue, 33
    add_ticket_type Tickets::TicketTypes::MenuIssue, 4
    add_ticket_type Tickets::TicketTypes::Item, 41
    add_ticket_type Tickets::TicketTypes::Offer, 42
    add_ticket_type Tickets::TicketTypes::OtherMenuIssue, 43
    add_ticket_type Tickets::TicketTypes::OtherIssue, 5
    add_ticket_type Tickets::TicketTypes::Other, 51
  end
end
