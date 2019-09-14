class LiteApp::Presenter::Order
  def initialize(dto:)
    @dto = dto
  end

  def present
    attrs = {
      id: @dto.id,
      backend_id: @dto.backend_id,
      order_key: @dto.order_key,
      status: @dto.status,
      status_name: @dto.status_detail&.name,
      store: LiteApp::Presenter::Store.new(dto: @dto.store).present,
      customer_notes: @dto.customer_notes,
      amount: @dto.amount,
      discount: @dto.discount,
      delivery_fee: @dto.delivery_fee,
      collect_at_customer: @dto.collect_at_customer,
      collect_at_pickup: @dto.collect_at_pickup,
      offer_applied: @dto.offer_applied,
      coupon: @dto.coupon,
      returnable: @dto.returnable,
      return_code: @dto.return_code,
      returned_status: @dto.returned_status,
      payment_type: @dto.payment_type,
      order_type: @dto.order_type,
      currency: @dto.currency&.name,
      received_at: @dto.created_at.to_i,
      state_key: @dto.state,
      state_name: @dto.state_name,
      transmission_medium: @dto.transmission_medium,
      integration_order: nil,
      rush_delivery: @dto.rush_delivery,
      delivery_type: @dto.delivery_type,
      can_mark_delivered: !!(@dto&.delivery_type_detail&.can_mark_delivered)
    }
    attrs[:line_items] = line_items if @dto.line_items
    attrs[:platform] = LiteApp::Presenter::Platform.new(dto: @dto.platform).present if @dto.platform
    attrs[:customer] = LiteApp::Presenter::Customer.new(dto: @dto.customer).present(customer_address: @dto.customer_address) if @dto.customer && @dto.customer_address
    attrs[:integration_order] = {id: @dto.integration_order.id, external_reference: @dto.integration_order.external_reference} if @dto.integration_order.present?
    attrs
  end

  def self.columns
    ["Dome ID", "PLatform ID", "Integration ID", "Status", "Store ID", "Store Name", "Amount", "Payment Type", "Time"]
  end

  def to_a
    [
      @dto.id,
      @dto.backend_id,
      @dto.integration_order&.external_reference,
      @dto.state_name,
      @dto.store&.id,
      @dto.store&.name_en,
      @dto.amount,
      @dto.payment_type,
      @dto.created_at.in_time_zone("Asia/Riyadh").iso8601, # TODO Set timezoune based on country
    ]
  end

  def line_items
    @dto.line_items.map do |line_item|
      {
        id: line_item.id,
        quantity: line_item.quantity,
        total_price: line_item.total_price,
        image: line_item.image,
        discount: line_item.discount,
        name: line_item.name,
        description: line_item.description,
        modifiers: modifiers(line_item),
      }
    end
  end

  def modifiers(line_item)
    line_item.modifiers.map do |modifier|
      {
        id: modifier.id,
        quantity: modifier.quantity,
        name: modifier.name,
        group: modifier.group,
      }
    end
  end
end
