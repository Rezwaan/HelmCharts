class Tickets::TicketTypes::Root < ::Tickets::TicketType
  @title = "Root"
  @type = TicketTypeKinds::ROOT

  class << self
    def is_applicable_for?(object = nil, _creator = nil)
      all_objects(object)
    end

    def content(_object = nil)
      "this is ROOT ticketType and nothing else"
    end
  end

  add_child Tickets::TicketTypes::Technical
  add_child Tickets::TicketTypes::FinancialIssue
  add_child Tickets::TicketTypes::MenuIssue
  add_child Tickets::TicketTypes::OtherIssue
end
