class Tickets::TicketTypes::Item < Tickets::TicketTypes::BasicCreateTicket
  @title = "item"
  @type = TicketTypeKinds::CREATABLE
end
