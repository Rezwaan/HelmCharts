class Tickets::TicketTypes::Payment < Tickets::TicketTypes::BasicCreateTicket
  @title = "payment"
  @type = TicketTypeKinds::CREATABLE
end
