class Orders::RushOrderService
  def create(attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)

    customer = Customers::CustomerService.new.find_or_create(platform_id: attributes[:platform_id], attributes: attributes[:customer])
    return customer if customer.blank? || customer.is_a?(ActiveModel::Errors)

    customer_address = Customers::CustomerService.new.find_or_create_address(customer_id: customer.id, attributes: attributes[:customer][:address])
    return customer_address if customer_address.blank? || customer_address.is_a?(ActiveModel::Errors)

    currency = Currencies::CurrencyService.new.fetch_by_key(key: attributes[:currency].to_s.downcase)
    return if currency.blank?

    order = Orders::Order.new

    order.order_key = SecureRandom.uuid

    order.backend_id = attributes[:backend_id]
    order.platform_id = attributes[:platform_id]
    order.amount = attributes[:payment][:amount]
    order.discount = attributes[:payment][:discount]
    order.delivery_fee = attributes[:payment][:delivery_fee]
    order.collect_at_customer = attributes[:payment][:collect_at_customer]
    order.collect_at_pickup = attributes[:payment][:collect_at_pickup]
    order.store_id = attributes[:store_id]

    order.currency_id = currency.id
    order.customer_id = customer.id
    order.customer_address_id = customer_address.id

    if attributes[:payment][:payment_type].to_s.in?(Orders::Order.payment_types.keys)
      order.payment_type = attributes[:payment][:payment_type]
    end

    build_line_items(order, attributes[:line_items])

    create_dto(order) if order.save!
  end

  def update_status(attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)

    order = Orders::Order.find(attributes[:backend_id])
    order.collect_at_customer = attributes[:collect_at_customer]
    order.collect_at_pickup = attributes[:pay_at_pickup]

    rush_delviery = RushDeliveries::RushDelivery.find_by(order_id: attributes[:backend_id])
    rush_delviery.status = attributes[:status]

    ActiveRecord::Base.transaction do
      order.save!
      rush_delviery.save!
    end
  end

  private

  def build_line_items(order, line_items)
    line_items&.each do |line_item|
      attributes = {
        backend_id: line_item[:backend_id],
        quantity: line_item[:quantity],
        total_price: line_item[:total_price],
        item_reference: line_item[:item_reference],
        discount: line_item[:discount],
        name_en: get_translations_attributes(line_item, :en, :name) || line_item[:name],
        name_ar: get_translations_attributes(line_item, :ar, :name) || line_item[:name],
        description_en: get_translations_attributes(line_item, :en, :notes) || line_item[:notes],
        description_ar: get_translations_attributes(line_item, :ar, :notes) || line_item[:notes],
        item_detail: line_item[:item_detail],
      }
      order_line_item = order.order_line_items.build(attributes)
      line_item.dig(:modifiers)&.each do |modifier|
        modifier_attributes = {
          quantity: modifier[:quantity],
          item_reference: modifier[:item_reference],
          name_en: get_translations_attributes(modifier, :en, :name) || modifier[:name],
          name_ar: get_translations_attributes(modifier, :ar, :name) || modifier[:name],
          group_en: get_translations_attributes(modifier, :en, :group) || modifier[:group],
          group_ar: get_translations_attributes(modifier, :ar, :group) || modifier[:group],
        }
        order_line_item.order_line_item_modifiers.build(modifier_attributes)
      end
    end
  end

  def get_translations_attributes(object, locale, field)
    ((object.dig(:translations_attributes) || []).detect { |attribute| attribute[:locale].to_s == locale.to_s } || {})[field]
  end

  def create_dto(order)
    return unless order

    attrs = {
      id: order.id,
      backend_id: order.backend_id,
      order_key: order.order_key,
      status: order.status,
      status_detail: order.status_detail,
      state: order.state,
      state_name: order.state_name,
      platform_id: order.platform_id,
      amount: order.amount,
      delivery_fee: order.delivery_fee,
      collect_at_customer: order.collect_at_customer,
      collect_at_pickup: order.collect_at_pickup,
      payment_type: order.payment_type,
      order_type: order.order_type,
      currency: order.currency,
      transmission_medium: order.transmission_medium,
    }

    attrs[:customer] = Customers::CustomerService.new.fetch(id: order.customer_id)
    attrs[:customer_address] = Customers::CustomerService.new.fetch_address(address_id: order.customer_address_id)

    Orders::OrderDTO.new(attrs)
  end
end
