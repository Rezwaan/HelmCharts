class OrderReceivers::Platform::PubSub::CreateListen < OrderReceivers::Platform::PubSub::Listen
  def order_create
    listen
  end

  def subscription_name
    Rails.application.secrets.dig(:pub_sub, @configuration, :subscriptions, :create)
  end

  def perform_action(msg_data, message_id)
    attributes = msg_data.dig("payload")
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    order = Orders::OrderService.new.create(attributes: attributes)
    result = order.present? && !order.is_a?(ActiveModel::Errors)
    if order&.is_a?(ActiveModel::Errors)
      result = true
      message = "Error: #{order.full_messages.join(", ")}"
      puts(message)
      Rails.logger.error(message)
      backend_id = (attributes || {})[:backend_id]
      order_key = (attributes || {})[:order_key]
      platform_id = ((attributes || {})[:platform] || {})[:backend_id]
      Orders::OrderService.new.publish_failed(backend_id: backend_id, platform_id: platform_id, order_key: order_key)
    elsif order
      result = true
      puts(order.inspect)
    end
    result
  end
end
