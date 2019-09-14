class Orders::Hooks::AfterCancelledAfterPickupByPlatform
  def initialize(order:)
    @order = order
  end

  def run(old_status:)
    # System will not create task as it's already picked up by rider
    #::Tasks::TaskService.new.create(task_type: 'order_cancelation', related_to_type: 'Orders::Order', related_to_id: @order.id, store_id: @order.store_id) if old_status.to_s == 'accepted_by_store'
  end
end
