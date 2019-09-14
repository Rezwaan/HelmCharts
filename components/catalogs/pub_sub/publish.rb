class Catalogs::PubSub::Publish
  def catalog_updated(data:, update: :content_updated)
    return unless enabled?

    transmit_data = presenter(event_name: event_names[update], payload: data)
    publish_data = {}
    configuration = :default
    ::PubSub::Workers::AsyncPublish.perform_async(
      topics[:catalog_updated],
      transmit_data.to_json,
      publish_data,
      configuration,
    )
  end

  def catalog_assigned(data:, update: :assigned)
    return unless enabled?

    transmit_data = presenter(event_name: event_names[update], payload: data)
    publish_data = {}
    configuration = :default
    ::PubSub::Workers::AsyncPublish.perform_async(
      topics[:catalog_updated],
      transmit_data.to_json,
      publish_data,
      configuration,
    )
  end

  private

  def topics
    ((Rails.application.secrets.pub_sub || {})[:catalog] || {})[:topics] || {}
  end

  def event_names
    ((Rails.application.secrets.pub_sub || {})[:catalog] || {})[:event_names] || {}
  end

  def enabled?
    !!(((Rails.application.secrets.pub_sub || {})[:catalog] || {})[:enabled])
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
