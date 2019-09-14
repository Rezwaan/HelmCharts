class Tickets::TicketTypes::Application < Tickets::TicketTypes::BasicCreateTicket
  @title = "application"
  @type = TicketTypeKinds::CREATABLE
end
