require "google/cloud/pubsub"
class PubSub::PubSub
  def initialize(configuration: :default, configurations: nil)
  end

  private

  def pubsub_config
    @pubsub ||= Google::Cloud::Pubsub.new keyfile: Google::Auth::GCECredentials.new
  end
end
