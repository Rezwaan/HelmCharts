class Tickets::TicketTypes::FinancialIssue < ::Tickets::TicketTypes::BasicParentIssue
  @title = "financial_issue"
  @type = TicketTypeKinds::PARENT

  add_child Tickets::TicketTypes::OrderAmount
  add_child Tickets::TicketTypes::Payment
  add_child Tickets::TicketTypes::OtherFinancialIssue
end
