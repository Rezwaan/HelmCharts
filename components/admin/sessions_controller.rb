class Admin::SessionsController < Admin::ApplicationController
  skip_before_action :authenticate!, only: %i[create]

  def me
    skip_authorization

    render json: {account: account_presenter(@current_account)}
  end

  def create
    skip_authorization

    begin
      account = Accounts::Account.not_deleted.where(username: params[:username]).first!

      # Check password
      raise ActiveRecord::RecordNotFound unless account.valid_password?(params[:password])
    rescue ActiveRecord::RecordNotFound
      return invalid_credentials_response
    end

    token_data = Accounts::AccountService.generate_token(account)

    render json: token_data
  end

  private

  def invalid_credentials_response
    render json: {error: "Username/Password doesn't match"}, status: :unauthorized
  end

  def account_presenter(account)
    {
      id: account.id,
      username: account.username,
      name: account.name,
      email: "#{account.username}@lite.posdome.com",
      roles: account.roles.map do |role|
        {
          id: role.id,
          role: role.role,
          role_resource_type: role.role_resource_type,
          role_resource_id: role.role_resource_id,
        }
      end,
    }
  end
end
