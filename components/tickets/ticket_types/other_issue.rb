class Tickets::TicketTypes::OtherIssue < ::Tickets::TicketTypes::BasicParentIssue
  @title = "other_issue"
  @type = TicketTypeKinds::PARENT

  add_child Tickets::TicketTypes::Other
end
