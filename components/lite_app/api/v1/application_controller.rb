require "hawk"

class LiteApp::Api::V1::ApplicationController < ApplicationController
  include Pundit
  include ActionController::Caching

  before_action :authenticate!
  before_action :authorize!
  before_action :set_pagination
  before_action :set_locale

  attr_reader :current_locale, :current_device, :current_account

  private

  def authenticate!
    return head :unauthorized if request.authorization.blank?

    token_type = request.authorization.split(" ").first

    case token_type
    when "Bearer"
      return head :unauthorized unless authenticate_bearer_request
    when "Hawk"
      return head :unauthorized unless authenticate_hawk_request

      account_id = @current_device.dig(:account_id)
      @current_account ||= Accounts::AccountService.new.find(id: account_id)
    end
  end

  def authenticate_bearer_request
    token = request.authorization.split(" ").second
    account_service = Accounts::AccountService.new
    @current_account = account_service.authenticate(token: token)
  end

  def authenticate_hawk_request
    payload = request.method.in?(%w[POST PUT PATCH]) ? request.body.read : nil
    hawkeys = ::Hawk::Server.authenticate(
      request.headers["Authorization"].to_s,
      method: request.method,
      request_uri: request.env["REQUEST_URI"],
      host: request.host,
      port: request.port,
      content_type: request.headers["Content-Type"],
      credentials_lookup: lambda { |id| Devices::DeviceService.new.get_credentials(auth_id: id) },
      nonce_lookup: lambda { |_| },
      payload: payload
    )

    if hawkeys.is_a?(Hash) && hawkeys[:id].present? && hawkeys[:key].present?
      @current_device = Devices::DeviceService.new.fetch(auth_id: hawkeys[:id], auth_key: hawkeys[:key])
      return true
    end

    if hawkeys.is_a?(Hawk::AuthenticationFailure) && hawkeys.key.to_s == "ts"
      response.set_header("Server-Authorization", hawkeys.header)
    end

    nil
  end

  def authorize!
    head :forbidden if current_account.blank? || account_store_ids.blank?
  end

  def set_pagination
    @page = params[:page].to_i
    @page = 1 unless @page.positive?

    @per_page = params[:per_page].to_i
    @per_page = 50 unless @per_page.in? [10, 50, 100, 200]
    @per_page, @page = [nil, 1] if params[:per_page].to_i == 0 && params[:all_records]
  end

  def set_locale
    I18n.locale = I18n.default_locale
    if @current_device && I18n.available_locales.include?(@current_device.language.to_sym)
      I18n.locale = @current_device.language.to_s
    end
    @current_locale = Locales::LocaleService.new.fetch_by_key(key: I18n.locale)
  end

  def store_ids_from_criteria(criteria)
    return [] unless criteria.present?
    store_ids = criteria.dig(:store_ids)
    store_ids = store_ids.to_unsafe_h.to_a.map(&:last) unless store_ids.nil? || store_ids.is_a?(Array)

    # Sending `store_id` is deprecated.
    store_id = criteria.dig(:store_id)
    store_ids = Array(store_id) if store_id.present?

    store_ids || []
  end

  def authorize_store_ids
    store_ids = store_ids_from_criteria(params.dig(:criteria))

    head :forbidden unless (store_ids.map(&:to_s) - account_store_ids.map(&:to_s)).blank?
  end

  def account_store_ids
    if @account_store_ids.nil? && current_account && current_account.roles.present?
      store_ids = current_account.roles.map { |role| role[:role] == "reception" && role[:role_resource_type] == "Stores::Store" ? role[:role_resource_id] : nil }.compact
      brand_ids = current_account.roles.map { |role| role[:role] == "reception" && role[:role_resource_type] == "Brands::Brand" ? role[:role_resource_id] : nil }.compact

      if brand_ids.any?
        criteria = {brand_id: brand_ids}
        store_ids += Stores::StoreService.new.ids(criteria: criteria)
      end

      @account_store_ids = store_ids.compact
    end
    @account_store_ids || []
  end

  def pundit_user
    current_account
  end
end
