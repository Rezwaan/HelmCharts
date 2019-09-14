class Orders::Hooks::AfterOutForDelivery
  def initialize(order:)
    @order = order
  end

  def run(author:)
    Orders::OrderService.new.publish_pubsub(order: @order, status: :accepted) unless author&.entity == 'platforms/swyft'
  end
end
