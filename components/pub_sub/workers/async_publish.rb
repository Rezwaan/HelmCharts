class PubSub::Workers::AsyncPublish
  include Sidekiq::Worker
  def perform(topic, message = nil, publish_data = {}, configuration = :default)
    PubSub::Publisher.new(configuration: configuration).publish(topic: topic, publish_data: publish_data, message: message)
  end
end
