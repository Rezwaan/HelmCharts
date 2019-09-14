class OrderReceivers::Platform::PubSub::UpdateListen < OrderReceivers::Platform::PubSub::Listen
  def order_update
    listen
  end

  def subscription_name
    (((Rails.application.secrets.pub_sub || {})[@configuration] || {})[:subscriptions] || {})[:update]
  end

  def perform_action(msg_data, message_id)
    result = false
    if msg_data&.dig("payload", "status").present?
      order_id = msg_data&.dig("payload", "backend_id").to_i
      platform_id = msg_data&.dig("payload", "platform_id").to_i
      platform = ::Platforms::PlatformService.new.fetch_by_backend_id(backend_id: platform_id) if platform_id > 0
      order = ::Orders::OrderService.new.fetch_by_backend_id(platform_id: platform.id, backend_id: order_id) if platform
      author = Author.by_system(entity: "platforms/swyft")
      if order
        begin
          case msg_data&.dig("payload", "status")
          when "canceled"
            if msg_data&.dig("payload", "picked_up")
              Orders::StatusUpdater.new(order: order, author: author).cancelled_after_pickup_by_platform
            else
              Orders::StatusUpdater.new(order: order, author: author).cancelled_by_platform
            end
          when 'picked_up_for_delivery', 'on_the_way', 'delivered_successfully'
            Orders::StatusUpdater.new(order: order, author: author).out_for_delivery
          end
        rescue Orders::Error::StatusChangedNotAllowed => _
        end
        result = true
      else
        Rails.logger.error("Update Listener Order Not found => #{order_id}")
        event_time = Time.at(msg_data["eventTime"])
        # if the message is older than  2 hours and order still not found then drop it
        if event_time < Time.now - 2.hours
          result = true
        end
      end
    end
    result
  end
end
