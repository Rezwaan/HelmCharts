class Admin::OrdersController < Admin::ApplicationController
  before_action :set_order_dto, only: :marshal

  def marshal
    authorize(Orders::Order)

    return render(status: :not_found) unless @order_dto

    send_data(
      Marshal.dump(@order_dto),
      file_name: "#{@order_dto.id}.bin"
    )
  end

  private

  def marshal_params
    params.permit(:id)
  end

  def set_order_dto
    @order_dto = Orders::OrderService.new.fetch(id: marshal_params[:id])
  end
end
