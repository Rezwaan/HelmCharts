class Admin::AccountRolesController < Admin::ApplicationController
  before_action :set_account

  def create
    authorize(@account)

    @account.roles.create!(
      role: params[:role],
      role_resource_type: params[:role_resource_type],
      role_resource_id: params[:role_resource_id],
    )

    render json: present_account(@account)
  end

  def destroy
    authorize(@account)

    @account.roles.find(params[:id]).destroy

    render json: present_account(@account)
  end

  private

  def set_account
    @account = Accounts::Account.find(params[:account_id])
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
