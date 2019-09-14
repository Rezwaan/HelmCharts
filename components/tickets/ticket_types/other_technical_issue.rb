class Tickets::TicketTypes::OtherTechnicalIssue < ::Tickets::TicketTypes::BasicCreateTicket
  @title = "other_technical_issue"
  @type = TicketTypeKinds::CREATABLE
end
