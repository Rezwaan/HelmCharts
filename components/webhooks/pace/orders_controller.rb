class Webhooks::Pace::OrdersController < ApplicationController
  before_action :authenticate!

  def update_order
    Orders::RushOrderService.new.update_status(attributes: order_params)
    head :ok
  end

  private

  def order_params
    params.permit(
      :backend_id,
      :collect_at_customer,
      :pay_at_pickup,
      :status,
    )
  end

  def authenticate!
    token = request.authorization

    head :unauthorized unless RushDeliveries::Pace::Helpers::Authenticator.new.authenticate(token: token)
  end
end
