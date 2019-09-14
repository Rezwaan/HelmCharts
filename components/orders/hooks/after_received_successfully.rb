class Orders::Hooks::AfterReceivedSuccessfully
  def initialize(order:)
    @order = order
  end

  def run
    Orders::OrderService.new.publish_pubsub(order: @order, status: :received)
    Integrations::IntegrationService.new.create_order(order: @order)
  end
end
