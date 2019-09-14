class PubSub::V1::OrdersController < PubSub::V1::ApplicationController
  def order_created
    attributes = @payload
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    order = Orders::OrderService.new.create(attributes: attributes)
    return head :created if order.present? && !order.is_a?(ActiveModel::Errors)

    return head :internal_server_error if order.nil?

    message = "Error: #{order.full_messages.join(", ")}"
    Rails.logger.error(message)

    attributes ||= {}
    backend_id = attributes.dig(:backend_id)
    order_key = attributes.dig(:order_key)
    platform_id = attributes.dig(:platform, :backend_id)

    Orders::OrderService.new.publish_failed(
      backend_id: backend_id,
      platform_id: platform_id,
      order_key: order_key,
    )

    head :unprocessable_entity
  end

  def order_updated
    if @payload["status"].to_s == "canceled"
      order_id = @payload["backend_id"]
      platform_id = @payload["platform_id"]
      platform = Platforms::PlatformService.new.fetch_by_backend_id(backend_id: platform_id) if platform_id > 0
      order = Orders::OrderService.new.fetch_by_backend_id(platform_id: platform.id, backend_id: order_id) if platform
      if order
        begin
          author = Author.by_system(entity: "platforms/swyft")
          Orders::StatusUpdater.new(order: order, author: author).cancelled_by_platform
        rescue Orders::Error::StatusChangedNotAllowed => _
        end
        result = true
      else
        return head :unprocessable_entity
      end
    end
    head :ok
  end
end
