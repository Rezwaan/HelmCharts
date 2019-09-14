class Admin::ApplicationController < ApplicationController
  include Pundit

  before_action :authenticate!
  before_action :set_pagination

  # Raise an exception if no call to `authorize` or `skip_authorization` was made.
  after_action :verify_authorized unless Rails.env.production?
  attr_reader :current_account, :current_account_dto

  private

  def page_response(collection, record_mapper: lambda { |r| r })
    render json: {
      data: collection.map(&record_mapper),
      total_records: collection.total_count,
      total_pages: collection.total_pages,
      status: true,
    }
  end

  def set_pagination
    @page = params[:page].to_i
    @page = 1 unless @page.positive?

    @per_page = params[:per_page].to_i
    @per_page = 50 unless @per_page.in? [10, 50, 100, 200, 1000]
    @per_page, @page = [nil, 1] if params[:per_page].to_i == 0 && params[:all_records]

    @sort_direction = params[:sort_direction]&.to_s&.downcase
    @sort_direction = "asc" unless @sort_direction == "desc"
  end

  def authenticate!
    return head :unauthorized if request.authorization.blank?

    token_type = request.authorization.split(" ").first
    return head :unauthorized unless token_type == "Bearer"

    token = request.authorization.split(" ").second
    data = JWT.decode(token, nil, false).first
    begin
      account = Accounts::Account.find(data["account_id"])

      # Ensure token signature is valid
      JWT.decode(token, account.encrypted_password, true)
      @current_account_dto = Accounts::AccountService.new.fetch(id: account.id)
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      return head :unauthorized
    end

    @current_account = account
  end

  def pundit_user
    current_account
  end
end
