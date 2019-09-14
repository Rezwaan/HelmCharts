class OrderReceivers::Platform::PubSub::Listen
  def initialize(configuration:)
    @configuration = configuration
    @listener =
      if is_sync_listen?
        ::PubSub::SyncListener.new(configuration: @configuration)
      else
        ::PubSub::AsyncListener.new(configuration: @configuration)
      end
  end

  def listen
    @running = true
    unless enabled?
      while @running
        sleep(5)
      end
    end
    if is_sync_listen?
      sync_listen
    else
      async_listen
    end
  end

  def async_listen
    @listener.listen(subscription_name: subscription_name, logger: logger) do |msg_data, message_id|
      logger.info("Data => #{message_id} => #{msg_data.inspect}") if log_data?
      perform_action(msg_data, message_id)
    end
  end

  def sync_listen
    @listener.pull(subscription_name: subscription_name, logger: logger, continuous: true) do |msg_data, message_id|
      logger.info("Data => #{message_id} => #{msg_data.inspect}") if log_data?
      perform_action(msg_data, message_id)
    end
  end

  def stop
    @listener.stop
    @running = false
  end

  def enabled?
    !!(((Rails.application.secrets.pub_sub || {})[@configuration] || {})[:enabled])
  end

  def logger
    @logger ||= Rails.logger || Logger.new(STDOUT)
  end

  def subscription_name
    raise "Need to implement"
  end

  def perform_action(msg_data, message_id)
    raise "Need to implement"
  end

  def is_sync_listen?
    !!(((Rails.application.secrets.pub_sub || {})[@configuration] || {})[:sync_listen])
  end

  def log_data?
    !!(((Rails.application.secrets.pub_sub || {})[@configuration] || {})[:log_data])
  end
end
