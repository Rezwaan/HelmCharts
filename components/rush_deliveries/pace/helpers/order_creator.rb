class RushDeliveries::Pace::Helpers::OrderCreator
  def generate_order(rush_delivery:)
    {
      backend_id: rush_delivery.order.id.to_s,
      delivery_address: drop_off_address(rush_delivery),
      pickup_address: pickup_address(rush_delivery.order),
      line_items: [],
      payment: "cash_on_delivery",
      delivery_fee: rush_delivery.order.delivery_fee,
      collect_at_customer: rush_delivery.order.collect_at_customer,
      prepaid_amount: prepaid_amount(order),
      pay_at_pickup: rush_delivery.order.collect_at_pickup,
      order_type: order_type(order),
      customer: customer_info(rush_delivery),
    }
  end

  private

  def drop_off_address(rush_delivery)
    {
      longitude: rush_delivery.drop_off_longitude,
      latitude: rush_delivery.drop_off_latitude,
      description: rush_delivery.drop_off_description,
      name: rush_delivery.customer_name,
      mobile: rush_delivery.customer_phone_number,
      backend_id: rush_delivery.id,
    }
  end

  def pickup_address(order)
    store = Stores::Store.find(order.store_id)

    {
      longitude: store.longitude,
      latitude: store.latitude,
      description: "",
      name: store.name,
      mobile: store.contact_number,
      backend_id: store.id,
    }
  end

  def prepaid_amount(order)
    (order.amount - order.discount) + order.delivery_fee - order.collect_at_customer
  end

  def order_type(order)
    order.store.brand.brand_category.key.to_s
  end

  def customer_info(rush_delivery)
    {
      backend_id: rush_delivery.id,
      mobile: rush_delivery.customer_phone_number,
      name: rush_delivery.customer_name,
    }
  end
end
