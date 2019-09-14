class Orders::StatusUpdater
  def initialize(order:, author:)
    @order = order
    @author = author
  end

  def received_successfully
    create_order_note(note_type: :received_successfully)
    Orders::Hooks::AfterReceivedSuccessfully.new(order: @order).run
    @order
  end

  def accepted_by_store
    return if update_order(params: {status: "accepted_by_store"}) == false
    create_order_note(note_type: :accepted_by_store)
    Orders::Hooks::AfterAcceptedByStore.new(order: @order).run
    @order
  end

  def out_for_delivery
    return if update_order(params: {status: "out_for_delivery"}) == false
    create_order_note(note_type: :out_for_delivery)
    Orders::Hooks::AfterOutForDelivery.new(order: @order).run(author: @author)
    @order
  end

  def delivered
    return unless @order&.delivery_type_detail&.can_mark_delivered
    return if update_order(params: {status: "delivered"}) == false
    create_order_note(note_type: :delivered)
    Orders::Hooks::AfterDelivered.new(order: @order).run(author: @author)
    @order
  end

  def cancelled_by_store
    return if update_order(params: {status: "cancelled_by_store"}) == false
    create_order_note(note_type: :cancelled_by_store)
    Orders::Hooks::AfterCancelledByStore.new(order: @order).run
    @order
  end

  def cancelled_by_platform
    old_status = @order.status
    return if update_order(params: {status: "cancelled_by_platform"}) == false
    create_order_note(note_type: :cancelled_by_platform)
    Orders::Hooks::AfterCancelledByPlatform.new(order: @order).run(old_status: old_status)
    @order
  end

  def cancelled_after_pickup_by_platform
    old_status = @order.status
    return if update_order(params: {status: "cancelled_after_pickup_by_platform"}) == false
    create_order_note(note_type: :cancelled_after_pickup_by_platform)
    Orders::Hooks::AfterCancelledAfterPickupByPlatform.new(order: @order).run(old_status: old_status)
    @order
  end

  def rejected_by_store(reject_reason_id: nil)
    return if update_order(params: {status: "rejected_by_store", reject_reason_id: reject_reason_id}) == false
    create_order_note(note_type: :rejected_by_store)
    Orders::Hooks::AfterRejectedByStore.new(order: @order).run
    @order
  end

  private

  def update_order(params:)
    if params[:status].present?
      return false if @order.status == params[:status]
      @order = Orders::OrderService.new.update_status(id: @order.id, status: params[:status], attributes: params.except(:status))
    end
    @order
  end

  def create_order_note(note_type:, note: nil)
    Orders::Notes::NoteService.new(order: @order, author: @author).build_note(note_type: note_type, note: note)
  end
end
