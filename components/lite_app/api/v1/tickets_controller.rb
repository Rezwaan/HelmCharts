class LiteApp::Api::V1::TicketsController < LiteApp::Api::V1::ApplicationController
  before_action :set_ticket_type_order, only: [:create]

  def ticket_type
    case params[:type].to_s.downcase
    when "order"
      criteria = {store_id: account_store_ids}.merge({id: params[:order_id]})

      @order_dto = Orders::OrderService.new.filter(criteria: criteria).first
      return invalid_order_response if @order_dto.blank?

      @ticket_types = Tickets::Core.tree_for_object(@order_dto, current_account)
    when "account"
      @ticket_types = Tickets::Core.tree_for_object(current_account, current_account)
    else
      @ticket_types = nil
    end

    return missing_type_response unless @ticket_types

    render json: @ticket_types
  end

  def create
    return ticket_action_missing_response if params[:ticket_action].blank?

    return ticket_action_invalid_response unless params[:ticket_action] == "create_ticket"

    action = Tickets::Actions::CreateTicketAction

    related_to = nil
    related_to_type = nil

    if @ticket_type.is_applicable_for?(@order_dto, current_account) &&
        @ticket_type.get_actions_for_object(@order_dto).include?(action) && (params[:ticket_action] == "create_ticket")
      related_to = @order_dto || current_account
      related_to_type = @order_dto ? Orders::Order.name : Accounts::Account.name
    elsif @ticket_type.is_applicable_for?(current_account, current_account) &&
        @ticket_type.get_actions_for_object(current_account).include?(action) && (params[:ticket_action] == "create_ticket")
      related_to = current_account
      related_to_type = Accounts::Account.name
    else
      return cannot_create_ticket_type_response
    end

    begin
      attributes = {
        data: params[:data],
        related_to: related_to,
        related_to_type: related_to_type,
        creator: current_account,
        creator_type: "Accounts::Account",
        attachments: params[:attachments],
      }
      result = Tickets::TicketService.new.create(ticket_type: @ticket_type, attributes: attributes)
    rescue => e
      Rails.logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
      return cannot_create_ticket_type_response
    end

    return ticket_duplicated_response if result[:error] == "duplicated"

    return cannot_create_ticket_type_response unless result.is_a? Tickets::TicketDTO

    render json: {message: I18n.t("api.success.your_ticket_was_successfully_submitted")}, status: :created
  end

  private

  def set_ticket_type_order
    case params[:type].to_s.downcase
    when "order"
      criteria = {store_id: account_store_ids}.merge({id: params[:order_id]})

      @order_dto = Orders::OrderService.new.filter(criteria: criteria).first
      return invalid_order_response if @order_dto.blank?

      @ticket_type = Tickets::Core.all_ticket_types[params[:code].to_i]
    when "account"
      @ticket_type = Tickets::Core.all_ticket_types[params[:code].to_i]
    else
      @ticket_type = nil
    end

    missing_ticket_response if @ticket_type.blank?
  end

  def invalid_order_response
    render json: {"error": I18n.t("api.error.order_not_present")}, status: :unprocessable_entity
  end

  def ticket_duplicated_response
    render json: {"error": I18n.t("api.error.duplicated_ticket")}, status: :unprocessable_entity
  end

  def missing_type_response
    render json: {"error": I18n.t("api.error.type_not_present")}, status: :unprocessable_entity
  end

  def missing_ticket_response
    render json: {"error": I18n.t("api.error.ticket_not_present")}, status: :unauthorized
  end

  def ticket_action_missing_response
    render json: {"error": I18n.t("api.error.action_param_is_required")}, status: :unprocessable_entity
  end

  def ticket_action_invalid_response
    render json: {"error": I18n.t("api.error.action_is_invalid")}, status: :unprocessable_entity
  end

  def cannot_create_ticket_type_response
    render json: {"error": I18n.t("api.error.can_not_create_this_type_of_ticket")}, status: :unprocessable_entity
  end
end
