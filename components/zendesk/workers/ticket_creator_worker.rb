class Zendesk::Workers::TicketCreatorWorker
  include Sidekiq::Worker

  def perform(related_to_class, related_to_id, zendesk_ticket_id)
    related_to =
      case related_to_class
      when "Tickets::Ticket"
        Zendesk::Presenters::Ticket.new(id: related_to_id)
      end
    presenter = related_to.present
    return unless presenter
    attachments = related_to.attachments
    zendesk_ticket = Zendesk::ZendeskTicketService.new.fetch(id: zendesk_ticket_id)
    if zendesk_ticket.zendesk_reference_id.blank?
      ticket = ZendeskAPI::Ticket.new($zendesk, presenter.deep_stringify_keys)
      attach_files(ticket, attachments)
      ticket.save!
      if ticket["error"].nil?
        Zendesk::ZendeskTicketService.new.update(id: zendesk_ticket_id, attrs: {zendesk_reference_id: ticket["id"]})
      end
    else
      ZendeskAPI::Ticket.update!($zendesk, presenter.deep_stringify_keys.merge(id: zendesk_ticket.zendesk_reference_id))
    end
  end

  private

  def attach_files(ticket, attachments = [])
    return unless attachments.present?
    begin
      attachments.collect do |attachment|
        file_path = "/tmp/#{attachment.id}_#{attachment.file_name}"
        File.write(file_path, File.read(URI.parse(attachment.url).open))
        ticket.comment.uploads << file_path
      end
    rescue
      ticket["comment"]["body"] = ticket["comment"]["body"] + "\n" + attachments.map(&:url).join("\n")
    end
  end
end
