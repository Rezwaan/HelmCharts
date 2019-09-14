class Tickets::TicketTypes::BasicParentIssue < ::Tickets::TicketType
  @type = TicketTypeKinds::PARENT

  class << self
    def is_applicable_for?(object = nil, creator = nil)
      is_account_dto?(object)
    end

    def tags
      [@title]
    end

    def content object = nil
      I18n.t("ticket_types.#{@title}.content")
    end
  end
end
