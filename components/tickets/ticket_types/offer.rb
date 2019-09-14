class Tickets::TicketTypes::Offer < Tickets::TicketTypes::BasicCreateTicket
  @title = "offer"
  @type = TicketTypeKinds::CREATABLE
end
