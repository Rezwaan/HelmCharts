class LiteApp::Api::V1::SessionsController < LiteApp::Api::V1::ApplicationController
  skip_before_action :authenticate!
  skip_before_action :authorize!

  def create
    token = Accounts::AccountService.new.login(
      username: params[:username],
      password: params[:password],
    )

    return render json: token, status: :unauthorized if token[:error].present?

    render json: token
  end
end
