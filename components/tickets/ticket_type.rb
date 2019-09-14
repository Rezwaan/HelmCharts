module Tickets
  class TicketType
    module TicketTypeKinds
      ROOT = 0 # there is only one ticket_type with this TYPE
      PARENT = 1 # has one or more sub-ticket as children
      DECLERATION = 2 # no need to create a ticket in DB
      CREATABLE = 3 # need to create a ticket
    end

    class << self
      include ActionView::Helpers::AssetUrlHelper
      attr_accessor :title, :type, :code

      def all_ticket_type_kinds
        {
          "ROOT" => 0,
          "PARENT" => 1,
          "DECLERATION" => 2,
          "CREATABLE" => 3,
        }
      end

      def all_ticket_type_kinds_enum
        all_ticket_type_kinds.invert
      end

      def parent_title
        @parent_storge ||= ""
      end

      def parent_code
        Tickets::Core.all_ticket_types_enum[parent_title]
      end

      def children
        @child_storage ||= []
      end

      def add_child ticket_type
        children << ticket_type
        ticket_type.add_parent(title)
      end

      def add_parent ticket_type
        parent_title << ticket_type
      end

      def kind
        all_ticket_type_kinds_enum[type]
      end

      # there aren't any tasks yet
      def tasks
        @tasks_storage ||= []
      end

      def add_task task
        tasks << task
      end

      def code
        Tickets::Core.all_ticket_types_enum[title]
      end

      def has_child?
        type.in?([TicketTypeKinds::ROOT, TicketTypeKinds::PARENT]) && children.any?
      end

      # this predicate method determines the ticket_type's required conditions
      def general_is_applicable_for? variable, creator = nil
        # if Ticket.where(related_to: variable, ticket_type: code).count > 0
        #   return false
        # end
        is_applicable_for? variable, creator
      end

      # content method must be overridden in CREATABLE and DECLERATION ticket_types
      # this method provides "appropriate content to present to user" and
      # "appropriate decleration for DECLERATION ticket_types"
      def content _variable = nil
        "Default content"
      end

      def content_html variable = nil
        content(variable)
      end

      def images
        []
      end

      def actions
        @actions ||= []
      end

      def applicable_actions(object:)
        get_actions_for_object(object).compact.select { |action| action.is_active_for_object?(object_class: object_class(object), object_id: object.id, ticket_type: self) }
      end

      def add_action action
        if action.superclass == Tickets::BaseAction
          actions.push action
        end
      end

      def get_actions_for_object(_object)
        []
      end

      def is_data_valid?(data, errors)
        fields.each do |field|
          errors.add(:data, "#{field[:key]} is required for data") if field[:required] && data[field[:key]].blank?
          errors.add(:data, "#{field[:key]} is not valid for data") if data[field[:key]].present? && !field[:type].is_valid?(value: data[field[:key]])
        end
      end

      def fields
        []
      end

      def create_dto(object)
        images = self.images.map { |image|
          meta = ::Paperclip::Geometry.from_file(Rails.root.to_s + "/app/assets/images/ticket_types/" + image)
          {
            url: image_url("ticket_types/" + image),
            width: meta.width,
            height: meta.height,
          }
        }
        Tickets::TicketTypeDTO.new(
          kind: kind,
          parent_code: parent_code,
          code: code,
          has_child: has_child?,
          title: I18n.t("ticket_types.#{title}.title"),
          content: content(object),
          content_html: content_html(object),
          actions: applicable_actions(object: object).map { |action| action.create_dto(object, self) },
          images: images,
          fields: fields.map { |field|
                    {
                      key: field[:key],
                      type: field[:type].name,
                      title: field[:title],
                      required: field[:required],
                    }
                  }
        )
      end

      protected

      def all_objects(object = nil)
        return false if object.nil?
        true
      end

      def is_order_dto?(object = nil)
        object.present? && object.class.name == "Orders::OrderDTO"
      end

      def is_account_dto?(object = nil)
        object.present? && object.class.name == "Accounts::AccountDTO"
      end

      def object_class(object)
        case object.class.name
        when "Orders::OrderDTO"
          "Orders::Order"
        when "Accounts::AccountDTO"
          "Accounts::Account"
        else
          object.class.name
        end
      end
    end

    # "TITLE" conditions:
    # 1- must be unique
    # 2- whitespaces and special chars are forbidden
    @title = "default_title"

    # "CODE" conditions:
    # 1- must be unique
    # 2- first  level ticket_types codes are Single-digit
    #    second level ticket_types codes are Single-digit and so on
    # 3- "0" is for ROOT
    # @code    = nil
  end
end
