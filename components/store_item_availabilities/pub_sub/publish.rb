class StoreItemAvailabilities::PubSub::Publish
  def publish_store_items(data:, event:, topic:)
    return unless enabled?

    transmit_data = presenter(event_name: event_names[event], payload: data)
    publish_data = {}
    configuration = :default
    ::PubSub::Workers::AsyncPublish.perform_async(
      topics[topic],
      transmit_data.to_json,
      publish_data,
      configuration,
    )
  end

  private

  def topics
    Rails.application.secrets.pub_sub&.dig(:store_items, :topics) || {}
  end

  def event_names
    Rails.application.secrets.pub_sub&.dig(:store_items, :event_names) || {}
  end

  def enabled?
    pub_sub_secrets = Rails.application.secrets.pub_sub
    enabled = pub_sub_secrets&.dig(:store_items, :enabled)

    # Ensure we're returning a truthy or falsy value (true or false/nil)
    ActiveModel::Type::Boolean.new.cast(enabled)
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
