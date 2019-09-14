class Stores::PubSub::Publish
  def update_store_status(data:, status: :ready)
    return unless enabled?
    transmit_data = presenter(event_name: event_names[status], payload: data)
    ::PubSub::Workers::AsyncPublish.perform_async(topics[:update_store_status], transmit_data.to_json, publish_data = {}, configuration = :default)
  end

  def update_store_pos_activation(data:, status: :pos_activated)
    return unless enabled?
    transmit_data = presenter(event_name: event_names[status], payload: data)
    ::PubSub::Workers::AsyncPublish.perform_async(topics[:update_store_pos_activation], transmit_data.to_json, publish_data = {}, configuration = :default)
  end

  def update_working_times(data:, status: :working_hours_updated)
    return unless enabled?
    transmit_data = presenter(event_name: event_names[status], payload: data)
    ::PubSub::Workers::AsyncPublish.perform_async(topics[:update_store_working_hours], transmit_data.to_json, publish_data = {}, configuration = :default)
  end

  def publish_store(data:, event:, topic:)
    return unless enabled?
    transmit_data = presenter(event_name: event_names[event], payload: data)
    ::PubSub::Workers::AsyncPublish.perform_async(topics[topic], transmit_data.to_json, publish_data = {}, configuration = :default)
  end

  private

  def topics
    ((Rails.application.secrets.pub_sub || {})[:store] || {})[:topics] || {}
  end

  def event_names
    ((Rails.application.secrets.pub_sub || {})[:store] || {})[:event_names] || {}
  end

  def enabled?
    !!(((Rails.application.secrets.pub_sub || {})[:store] || {})[:enabled])
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
