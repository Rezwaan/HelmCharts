class Orders::Hooks::AfterAcceptedByStore
  def initialize(order:)
    @order = order
  end

  def run
    Orders::OrderService.new.publish_pubsub(order: @order, status: :accepted)
  end
end
