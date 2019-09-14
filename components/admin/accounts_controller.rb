class Admin::AccountsController < Admin::ApplicationController
  before_action :set_account, only: [:show, :update, :destroy]

  def index
    authorize(Accounts::Account)

    accounts = Accounts::AccountService.new.filter(
      criteria: params.dig(:criteria) || {},
      page: @page,
      per_page: @per_page,
      sort_by: :created_at,
      sort_direction: "desc",
    )

    page_response(accounts)
  end

  def show
    authorize(@account)

    render json: present_account(@account)
  end

  def create
    authorize(Accounts::Account)

    account = Accounts::Account.create!(create_params)

    render json: present_account(account)
  end

  def update
    authorize(@account)

    @account.update!(update_params)

    render json: present_account(@account)
  end

  def destroy
    authorize(@account)

    @account.update!(deleted_at: Time.now)

    render json: present_account(@account)
  end

  def roles
    account = Accounts::AccountService.new.update_roles(account_id: params[:id], roles: update_roles_params)

    render json: present_account(account)
  end

  private

  def set_account
    @account = Accounts::Account.not_deleted.find(params[:id])
  end

  def index_params
    params.permit(:page, :per_page,).to_h.symbolize_keys
  end

  def create_params
    params.permit(:name, :username, :password).to_h
  end

  def update_params
    params.permit(:name, :password).to_h
  end

  def update_roles_params
    params.permit(roles: [:role, :role_resource_id, :role_resource_type]).require(:roles)
  end

  def present_account(account)
    {
      id: account.id,
      username: account.username,
      name: account.name,
      email: email_format % {username: account.username},
      roles: account.roles.map { |role| present_role(role) },
    }
  end

  def email_format
    format = Rails.application.secrets.accounts&.dig(:email_format)
    format.present? ? format : "%{username}@lite.posdome.com"
  end

  def present_role(role)
    {
      id: role.id,
      role: role.role,
      role_resource_type: role.role_resource_type,
      role_resource_id: role.role_resource_id,
    }
  end
end
