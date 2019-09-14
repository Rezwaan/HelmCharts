class Zendesk::Controllers::ZendeskController < ApplicationController
  def validate
    data = JWT.decode(params["user_token"], Rails.application.secrets.zendesk[:our_own_signing_token]).first
    case data["creator_type"]
    when Accounts::Account.name
      account = Accounts::AccountService.new.fetch(id: data["creator_id"])
      return render json: {jwt: authenticate_account(account: account)} if account
    end

    render json: {message: "Authentication Failed."}, status: :unauthorized
  rescue
  end

  private

  def authenticate_account(account:)
    iat = Time.now.to_i
    jti = "#{iat}/#{SecureRandom.hex(18)}"
    JWT.encode({
      iat: iat,
      jti: jti,
      name: (account[:name].blank? ? account[:username] : account[:name]),
      email: account[:email].downcase,
    }, Rails.application.secrets.zendesk[:shared_secret_token])
  end
end
