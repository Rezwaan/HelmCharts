class Orders::Hooks::AfterDelivered
  def initialize(order:)
    @order = order
  end

  def run(author:)
    Orders::OrderService.new.publish_pubsub(order: @order, status: :delivered) unless author&.entity == 'platforms/swyft'
  end
end
