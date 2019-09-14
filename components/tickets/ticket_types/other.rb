class Tickets::TicketTypes::Other < Tickets::TicketTypes::BasicCreateTicket
  @title = "other"
  @type = TicketTypeKinds::CREATABLE
end
