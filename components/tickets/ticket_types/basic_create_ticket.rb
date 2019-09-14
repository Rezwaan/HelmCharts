class Tickets::TicketTypes::BasicCreateTicket < ::Tickets::TicketType
  @type = TicketTypeKinds::CREATABLE

  class << self
    def is_applicable_for?(object = nil, creator = nil)
      is_account_dto?(object)
    end

    def content object = nil
      I18n.t("ticket_types.#{@title}.content")
    end

    def images
      []
    end

    def tags
      [@title]
    end

    def get_actions_for_object(object)
      [Tickets::Actions::CreateTicketAction]
    end

    def fields
      [
        {
          key: "content",
          type: Tickets::FieldTypes::TextFieldType,
          title: I18n.t("ticket_types.content"),
          required: true,
        },
      ]
    end
  end
end
