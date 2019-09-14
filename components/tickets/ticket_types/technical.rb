class Tickets::TicketTypes::Technical < ::Tickets::TicketTypes::BasicParentIssue
  @title = "technical"
  @type = TicketTypeKinds::PARENT

  add_child Tickets::TicketTypes::Account
  add_child Tickets::TicketTypes::Application
  add_child Tickets::TicketTypes::OtherTechnicalIssue
end
