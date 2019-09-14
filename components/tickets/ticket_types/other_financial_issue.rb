class Tickets::TicketTypes::OtherFinancialIssue < Tickets::TicketTypes::BasicCreateTicket
  @title = "other_financial_issue"
  @type = TicketTypeKinds::CREATABLE
end
