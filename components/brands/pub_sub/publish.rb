class Brands::PubSub::Publish
  def brand_publish(data:, event:, topic:)
    return unless enabled?
    transmit_data = presenter(event_name: event_names[event], payload: data)
    ::PubSub::Workers::AsyncPublish.perform_async(topics[topic], transmit_data.to_json, publish_data = {}, configuration = :default)
  end

  private

  def topics
    ((Rails.application.secrets.pub_sub || {})[:brand] || {})[:topics] || {}
  end

  def event_names
    ((Rails.application.secrets.pub_sub || {})[:brand] || {})[:event_names] || {}
  end

  def enabled?
    !!(((Rails.application.secrets.pub_sub || {})[:brand] || {})[:enabled])
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
