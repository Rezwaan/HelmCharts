class Orders::Hooks::AfterCancelledByStore
  def initialize(order:)
    @order = order
  end

  def run
    Orders::OrderService.new.publish_pubsub(order: @order, status: :rejected)
  end
end
