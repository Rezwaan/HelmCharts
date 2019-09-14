class Zendesk::Presenters::Ticket
  def initialize(id:)
    @ticket = Tickets::TicketService.new.fetch(id: id)
  end

  def present
    return if @ticket.data["content"].blank?

    {
      subject: "#{@ticket.ticket_type} /related_to_type: #{@ticket.ticket_type} /related_to_id: #{@ticket.related_to_id}",
      comment: {body: content},
      priority: "normal",
      requester_id: requester_id,
      custom_fields: custom_fields,
      tags: tags,
    }
  end

  def attachments
    Tickets::TicketService.new.attachments(id: @ticket.id)
  end

  private

  def tags
    [Rails.application.secrets.zendesk[:account_support_tag]] + ticket_tags
  end

  def ticket_tags
    Tickets::TicketService.new.get_ticket_class(ticket: @ticket)&.tags
  rescue
    []
  end

  def requester_id
    if @ticket.creator_type == Accounts::Account.name
      zendesk_user = Zendesk::UserService.new.find_or_create(account_id: @ticket.creator_id)
      zendesk_user[:id]
    else
      Rails.application.secrets.zendesk[:default_requester]
    end
  end

  def custom_fields
    if @ticket.related_to_type == Orders::Order.name
      order = Orders::OrderService.new.fetch(id: @ticket.related_to_id)
      [{id: Rails.application.secrets.zendesk[:order_id_ticket_field_id], value: order["backend_id"]}]
    end
  end

  def content
    @ticket.data["content"]
  end
end
