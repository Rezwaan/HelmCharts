class Orders::OrderService
  include Helpers::PaginationHelper

  def create(attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    platform = Platforms::PlatformService.new.find_or_create(attributes: attributes[:platform])
    return platform if platform.blank? || platform.is_a?(ActiveModel::Errors)

    customer = Customers::CustomerService.new.find_or_create(platform_id: platform.id, attributes: attributes[:customer])
    return customer if customer.blank? || customer.is_a?(ActiveModel::Errors)

    customer_address = Customers::CustomerService.new.find_or_create_address(customer_id: customer.id, attributes: attributes[:customer][:address])
    return customer_address if customer_address.blank? || customer_address.is_a?(ActiveModel::Errors)

    brand = Brands::BrandService.new.fetch_by_brand(brand: attributes[:store][:brand])
    return brand if brand.blank? || brand.is_a?(ActiveModel::Errors)

    store = Stores::StoreService.new.fetch_by_store(store: attributes[:store])
    return store if store.blank? || store.is_a?(ActiveModel::Errors)

    currency = Currencies::CurrencyService.new.fetch_by_key(key: attributes[:currency].to_s.downcase)
    return if currency.blank?

    begin
      order = Orders::Order.find_by(
        platform_id: platform.id,
        backend_id: attributes[:backend_id],
      )
      return create_dto(order) if order

      order = Orders::Order.new
      order.platform_id = platform.id
      order.backend_id = attributes[:backend_id]
      order.order_key = attributes[:order_key]
      order.customer_notes = attributes[:customer_notes]
      order.amount = attributes[:amount]
      order.discount = attributes[:discount]
      order.delivery_fee = attributes[:delivery_fee]
      order.collect_at_customer = attributes[:collect_at_customer]
      order.collect_at_pickup = attributes[:collect_at_pickup]
      order.offer_applied = attributes[:offer_applied]
      order.coupon = attributes[:coupon]
      order.returnable = attributes[:returnable]
      order.return_code = attributes[:return_code]
      order.returned_status = attributes[:returned_status]
      order.payment_type = attributes[:payment_type] if attributes[:payment_type].to_s.in?(Orders::Order.payment_types.keys)
      order.order_type = attributes[:order_type] if attributes[:order_type].to_s.in?(Orders::Order.order_types.keys)
      order.customer_id = customer.id
      order.customer_address_id = customer_address.id
      order.store_id = store.id
      order.currency_id = currency.id
      order.delivery_type = attributes[:delivery_type] if attributes[:delivery_type].present?

      build_line_items(order, attributes[:line_items])

      if order.save
        dto = create_dto(order)
        author = Author.by_system(entity: "platforms/swyft")
        Orders::StatusUpdater.new(order: dto, author: author).received_successfully
        send_notification(order: order)
        return dto
      end

      order.errors
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def fetch(id:, light: false)
    order = Orders::Order.find_by(id: id)
    create_dto(order, light: light)
  end

  def fetch_light(id:)
    order = Orders::Order.find_by(id: id)
    create_light_dto(order)
  end

  def fetch_by_backend_id(platform_id:, backend_id:)
    order = Orders::Order.find_by(platform_id: platform_id, backend_id: backend_id)
    create_dto(order)
  end

  def filter(criteria: {}, per_page: 50, page: 1, sort_by: :created_at, sort_direction: "desc", sort_multiple: {}, light: true)
    operation_time_range(criteria: criteria)

    orders = apply_scopes(criteria: criteria).includes(
      :platform,
      store: [{brand: :translations}, :translations, :store_status],
      order_line_items: [{order_line_item_modifiers: :translations}, :translations],
    )
    if sort_multiple.present?
      orders = orders.order(sort_multiple)
    elsif sort_by
      orders = orders.order(sort_by => sort_direction || "desc")
    end

    paginated_dtos(collection: orders, page: page, per_page: per_page) do |order|
      create_dto(order, light: light)
    end
  end

  def grouped_data(criteria: {}, field:, type: "orders")
    operation_time_range(criteria: criteria)

    scoped_orders = apply_scopes(criteria: criteria)
    Array(field).each do |f|
      scoped_orders = scoped_orders.group(f)
    end
    type.downcase == "orders" ? scoped_orders.count : scoped_orders.sum(:amount)
  end

  def update_status(id:, status:, attributes: {})
    order = Orders::Order.find_by(id: id)
    return unless order

    statuses = Orders::OrderStatus.allowed_from(status)
    unless Orders::Order.where(id: id, status: statuses + [0]).update_all(attributes.merge({status: status, updated_at: Time.now})) == 1
      raise Orders::Error::StatusChangedNotAllowed.new(message: status, error_data: order.inspect)
    end

    order.reload
    dto = create_dto(order)

    dto || create_dto(order)
  end

  def active(store_ids:)
    return [] unless store_ids.count > 0

    max_time = 1.hour
    criteria = {
      store_id: store_ids,
      created_at_range: [(Time.now - max_time), Time.now],
      alive_orders: true,
    }
    filter(criteria: criteria, per_page: 1000, page: 1, sort_by: :created_at, sort_direction: "desc", sort_multiple: {"status" => "asc", "created_at" => "asc"}, light: true)
  end

  def publish_failed(backend_id:, platform_id:, order_key:)
    data = {
      backend_id: backend_id,
      platform_id: platform_id,
      order_key: order_key,
      status: :canceled,
    }
    OrderReceivers::Platform::PubSub::Publish.new.update_status(data: data, status: :rejected)
  end

  def cancel_expired_order(platform_id:, expiry_minutes:, country_id: nil, prayer_time_exception: false)
    Orders::Order.where("created_at < ?", expiry_minutes.minutes.ago).where(status: "received_successfully", platform_id: platform_id).each do |order|
      if prayer_time_exception
        store = Stores::StoreService.new.fetch(id: order.store_id)
        prayer_time_service = PrayerTime::PrayerTimeService.new(latitude: store.latitude, longitude: store.longitude)
        next if prayer_time_service.currently_praying
      end

      begin
        author = Author.by_system(entity: "orders")
        Orders::StatusUpdater.new(order: create_dto(order), author: author).cancelled_by_store
      rescue Orders::Error::StatusChangedNotAllowed => _
      end
    end
  end

  def publish_pubsub(order:, status:)
    data = {
      id: order.id,
      backend_id: order.backend_id,
      platform_id: order.platform.backend_id,
      order_key: order.order_key,
      status: order.status,
      rejection_reason_id: order.reject_reason&.id,
      rejection_reason_text: order.reject_reason&.text,
    }
    OrderReceivers::Platform::PubSub::Publish.new.update_status(data: data, status: status)
  end

  def update_transmission(order_id:, transmission:)
    order = Orders::Order.find_by(id: order_id)
    return unless order

    order.update_attribute(:transmission_medium, transmission)

    create_dto(order)
  end

  private

  def build_line_items(order, line_items)
    line_items&.each do |line_item|
      attributes = {
        backend_id: line_item[:backend_id],
        quantity: line_item[:quantity],
        total_price: line_item[:price],
        item_reference: line_item[:item_reference],
        image: line_item[:image],
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

  def create_dto(order, light: false)
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
      customer_id: order.customer_id,
      store_id: order.store_id,
      store: Stores::StoreService.new.create_dto(order.store),
      customer_address_id: order.customer_address_id,
      customer_notes: order.customer_notes,
      amount: order.amount,
      discount: order.discount,
      delivery_fee: order.delivery_fee,
      collect_at_customer: order.collect_at_customer,
      collect_at_pickup: order.collect_at_pickup,
      offer_applied: order.offer_applied,
      coupon: order.coupon,
      returnable: order.returnable,
      return_code: order.return_code,
      returned_status: order.returned_status,
      payment_type: order.payment_type,
      order_type: order.order_type,
      currency: order.currency,
      reject_reason: RejectReasons::RejectReasonService.new.fetch(id: order.reject_reason_id),
      created_at: order.created_at,
      updated_at: order.updated_at,
      line_items: line_items_dto(order.order_line_items),
      platform: Platforms::PlatformService.new.create_dto(order.platform),
      transmission_medium: order.transmission_medium,
      integration_order: Integrations::IntegrationOrderService.new.filter(criteria: {order_id: order.id}).first,
      rush_delivery: order.rush_delivery,
      delivery_type: order.delivery_type,
      delivery_type_detail: order.delivery_type_detail
    }

    unless light
      attrs[:customer] = Customers::CustomerService.new.fetch(id: order.customer_id)
      attrs[:customer_address] = Customers::CustomerService.new.fetch_address(address_id: order.customer_address_id)
    end

    Orders::OrderDTO.new(attrs)
  end

  def line_items_dto(line_items)
    line_items.map do |line_item|
      Orders::OrderLineItemDTO.new(
        id: line_item.id,
        backend_id: line_item.backend_id,
        quantity: line_item.quantity,
        total_price: line_item.total_price,
        image: line_item.image,
        discount: line_item.discount,
        name: line_item.name,
        description: line_item.description,
        name_en: line_item.name_en,
        name_ar: line_item.name_ar,
        description_en: line_item.description_en,
        description_ar: line_item.description_ar,
        modifiers: modifiers_dto(line_item.order_line_item_modifiers),
        item_detail: line_item.item_detail
      )
    end
  end

  def modifiers_dto(modifiers)
    modifiers.map do |modifier|
      Orders::OrderLineItemModifierDTO.new(
        id: modifier.id,
        quantity: modifier.quantity,
        name: modifier.name,
        group: modifier.group,
        name_en: modifier.name_en,
        name_ar: modifier.name_ar,
        group_en: modifier.group_en,
        group_ar: modifier.group_ar
      )
    end
  end

  def create_light_dto(order)
    return unless order

    Orders::OrderDTO.new({
      id: order.id,
      backend_id: order.backend_id,
      order_key: order.order_key,
      status: order.status,
      status_detail: order.status_detail,
      state: order.state,
      state_name: order.state_name,
      platform_id: order.platform_id,
      store_id: order.store_id,
      amount: order.amount,
      payment_type: order.payment_type,
      order_type: order.order_type,
      currency: order.currency,
      transmission_medium: order.transmission_medium,
      delivery_type: order.delivery_type,
      delivery_type_detail: order.delivery_type_detail
    })
  end

  def operation_time_range(criteria: {})
    return unless criteria.dig(:operation_day, :start) && criteria.dig(:operation_day, :end)

    operation_day_start = Time.parse(criteria[:operation_day][:start]) + 3.hours
    operation_day_end = Time.parse(criteria[:operation_day][:end]) + 1.day + 3.hours
    criteria[:created_at_range] = [operation_day_start, operation_day_end]
  end

  def apply_scopes(criteria: {})
    orders = Orders::Order.where(nil)
    orders = orders.where(id: criteria[:id]) if criteria[:id].present?
    # Sending store_id is deprecated. Switch to store_ids.
    orders = orders.where(store_id: criteria[:store_id]) if criteria[:store_id].present?
    orders = orders.where(store_id: criteria[:store_ids]) if criteria[:store_ids].present?
    orders = orders.where(customer_id: criteria[:customer_id]) if criteria[:customer_id].present?
    orders = orders.where(platform_id: criteria[:platform_id]) if criteria[:platform_id].present?
    orders = orders.where(status: criteria[:status]) if criteria[:status].present?
    orders = orders.where(status: Orders::OrderStatus.statuses_by_state(criteria[:state].to_sym)) if criteria[:state].present?
    orders = orders.where(payment_type: criteria[:payment_type]) if criteria[:payment_type].present?
    orders = orders.where(status: [:received_successfully, :accepted_by_store]) if criteria[:active_only].present?
    orders = orders.where(status: [:received_successfully, :accepted_by_store, :out_for_delivery]) if criteria[:alive_orders].present?
    orders = orders.where(created_at: (criteria[:created_at_range].first)..(criteria[:created_at_range].last)) if criteria[:created_at_range].present?
    orders
  end

  def send_notification(order:, payload: {}, options: {})
    account_ids = Accounts::AccountService.new.account_ids_by_store(store: order.store)
    Notifications::Firebase::NotifierService.new(account_ids: account_ids).async.order_updated(id: order.id, payload: payload, options: options)
  end
end
