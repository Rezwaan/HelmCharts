module Tickets
  class TicketService
    def create(ticket_type:, attributes: {})
      @ticket_type = ticket_type
      @attributes = attributes
      if not_allowed_to_create
        raise "ticket type is not applicable for related_to"
      end

      if ticket_already_created(
        related_to_type: @attributes[:related_to_type],
        related_to_id: @attributes[:related_to].id,
        ticket_type: @ticket_type.code,
      ) || ticket_of_category_created
        return {error: "duplicated"}
      end
      ticket = Tickets::Ticket.new
      create_ticket(ticket)
      if ticket.save
        ticket_dto = create_dto(ticket)
        Zendesk::ZendeskTicketService.new.create(related_to: ticket_dto, related_to_class: "Tickets::Ticket")
        return ticket_dto
      end
      ticket.errors
    end

    def fetch(id:)
      ticket = Tickets::Ticket.find(id)

      create_dto(ticket) if ticket
    end

    def attachments(id:)
      ticket = Tickets::Ticket.find_by(id: id)
      return [] unless ticket

      ticket.ticket_attachments.map { |attachment| create_attachment_dto(attachment) }.compact
    end

    def ticket_already_created(related_to_type:, related_to_id:, ticket_type:)
      ticket_source = get_ticket_source(related_to_type)
      grace_minutes = minutes_to_create_next_ticket_by_ticket_source(ticket_source)
      grace_time = grace_minutes.minutes.ago..Time.now
      type_filtering = type_filtering_by_ticket_source(ticket_source)
      maximum_tickets = type_filtering ? 1 : maximum_tickets_by_ticket_source(ticket_source)
      Tickets::Ticket.where(related_to_type: related_to_type,
                            related_to_id: related_to_id, created_at: grace_time)
        .where(type_filtering ? {ticket_type: ticket_type} : {}).count >= maximum_tickets
    end

    def get_ticket_class(ticket:)
      ("Tickets::TicketTypes::" + ticket.ticket_type.classify).constantize if ticket.ticket_type.present?
    end

    private

    def create_dto(ticket)
      Tickets::TicketDTO.new(
        id: ticket.id,
        data: ticket.data.present? && ticket.data.is_a?(String) ? (begin
                                                                     JSON.parse(ticket.data)
                                                                   rescue
                                                                     ticket.data
                                                                   end) : ticket.data,
        ticket_type: ticket.ticket_type,
        related_to_type: ticket.related_to_type,
        related_to_id: ticket.related_to_id,
        creator_type: ticket.creator_type,
        creator_id: ticket.creator_id,
        created_at: ticket.created_at,
      )
    end

    def create_attachment_dto(attachment)
      return unless attachment && attachment.file_attachment.present?

      Tickets::TicketAttachmentDTO.new(
        id: attachment.id,
        url: attachment.file_attachment.url,
        ticket_id: attachment.ticket_id,
        file_name: attachment.file_attachment_file_name,
        content_type: attachment.file_attachment_content_type,
        file_size: attachment.file_attachment_file_size,
        created_at: attachment.created_at
      )
    end

    def create_ticket(ticket)
      ticket.ticket_type = @ticket_type.code
      ticket.data = @attributes[:data]
      ticket.related_to_id = @attributes[:related_to].id
      ticket.related_to_type = @attributes[:related_to_type]
      ticket.creator_id = @attributes[:creator].id
      ticket.creator_type = @attributes[:creator_type]
      puts @attributes.inspect
      begin
        Array(@attributes[:attachments]).each do |attachment|
          ticket.ticket_attachments.build(file_attachment: attachment)
        rescue
          nil
        end
      rescue => e
        Rails.logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      end
      ticket
    end

    def ticket_of_category_created
      return false if @attributes[:related_to_type] != Orders::Order.name

      tickets = Tickets::Ticket.where(related_to_type: @attributes[:related_to_type], related_to_id: @attributes[:related_to].id)
      return true if tickets.count >= maximum_tickets_by_ticket_source(:order) # current max Categories
      return false if tickets.count == 0

      tickets.each do |ticket|
        ticket_class = get_ticket_class(ticket: ticket)
        return true if ticket_class && ticket_class.parent_code == @ticket_type.parent_code
      end

      false
    end

    def not_allowed_to_create
      !@ticket_type.general_is_applicable_for?(@attributes[:related_to], @attributes[:creator])
    end

    def time_cap
      (Rails.application.secrets.tickets || {})[:time_cap] || {}
    end

    def minutes_to_create_next_ticket_by_ticket_source(ticket_source)
      ((time_cap[ticket_source] || {})[:minutes_to_create_next_ticket] || time_cap[:minutes_to_create_next_ticket] || 45).to_i
    end

    def maximum_tickets_by_ticket_source(ticket_source)
      ((time_cap[ticket_source] || {})[:maximum_tickets] || time_cap[:maximum_tickets] || 4).to_i
    end

    def type_filtering_by_ticket_source(ticket_source)
      type_filtering = nil
      type_filtering = (time_cap[ticket_source] || {})[:type_filtering] unless (time_cap[ticket_source] || {})[:type_filtering].nil?
      type_filtering = time_cap[:type_filtering] if type_filtering.nil?
      type_filtering = true if type_filtering.nil?
      type_filtering
    end

    def get_ticket_source(related_to_type)
      related_to_type == Accounts::Account.name ? :general : :order
    end
  end
end
