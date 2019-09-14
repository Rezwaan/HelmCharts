class PubSub::Publisher < PubSub::PubSub
  def publish(topic:, publish_data: {}, message: nil)
    pubsub_topic = pubsub_config.topic(topic)
    pubsub_topic.publish(message, publish_data)
  end
end
