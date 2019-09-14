module Zendesk
  class ZendeskTicketService
    def create(related_to:, related_to_class:)
      zendesk_ticket = Zendesk::ZendeskTicket.new
      zendesk_ticket.assign_attributes({related_to_type: related_to_class, related_to_id: related_to.id})

      if zendesk_ticket.save
        Zendesk::Workers::TicketCreatorWorker.perform_async(related_to_class, related_to.id, zendesk_ticket.id)
        create_dto(zendesk_ticket)
      else
        zendesk_ticket.errors
      end
    end

    def generate_token(creator_type:, creator_id:)
      JWT.encode({
        creator_type: creator_type,
        creator_id: creator_id,
      }, Rails.application.secrets.zendesk[:our_own_signing_token])
    end

    def validate_token(token:)
      data = JWT.decode(token, Rails.application.secrets.zendesk[:our_own_signing_token])

      JWT.encode({
        creator_type: data["creator_type"],
        creator_id: data["creator_id"],
      }, Rails.application.secrets.zendesk[:shared_secret_token])
    end

    def update(id:, attrs:)
      zendesk_ticket = Zendesk::ZendeskTicket.find(id)
      zendesk_ticket.assign_attributes(attrs)
      return create_dto(zendesk_ticket) if zendesk_ticket.save
      zendesk_ticket.errors
    end

    def fetch(id:)
      zendesk_ticket = Zendesk::ZendeskTicket.find_by(id: id)
      create_dto(zendesk_ticket) if zendesk_ticket
    end

    private

    def create_dto(zendesk_ticket)
      Zendesk::ZendeskTicketDTO.new(
        id: zendesk_ticket.id,
        zendesk_reference_id: zendesk_ticket.zendesk_reference_id,
        related_to_type: zendesk_ticket.related_to_type,
        related_to_id: zendesk_ticket.related_to_id,
        created_at: zendesk_ticket.created_at,
      )
    end
  end
end
