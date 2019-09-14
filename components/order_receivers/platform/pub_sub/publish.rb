class OrderReceivers::Platform::PubSub::Publish
  def update_status(data:, status: :accepted)
    return unless enabled?
    transmit_data = presenter(event_name: event_names[status], payload: data)
    ::PubSub::Workers::AsyncPublish.perform_async(topics[:update_status], transmit_data.to_json, publish_data = {}, configuration = :order)
  end

  private

  def topics
    ((Rails.application.secrets.pub_sub || {})[:order] || {})[:topics] || {}
  end

  def event_names
    ((Rails.application.secrets.pub_sub || {})[:order] || {})[:event_names] || {}
  end

  def enabled?
    !!(((Rails.application.secrets.pub_sub || {})[:order] || {})[:enabled])
  end

  def presenter(event_name:, payload: {})
    {
      "eventId": SecureRandom.uuid,
      "eventName": event_name,
      "eventTime": Time.now.to_i,
      "payload": payload,
    }
  end
end
