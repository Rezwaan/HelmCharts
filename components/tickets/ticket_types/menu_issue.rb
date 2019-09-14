class Tickets::TicketTypes::MenuIssue < ::Tickets::TicketTypes::BasicParentIssue
  @title = "menu_issue"
  @type = TicketTypeKinds::PARENT

  add_child Tickets::TicketTypes::Item
  add_child Tickets::TicketTypes::Offer
  add_child Tickets::TicketTypes::OtherMenuIssue
end
