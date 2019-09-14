class PubSub::AsyncListener < PubSub::PubSub
  def listen(subscription_name:, logger:, handle_exception: true)
    @running = true
    @database_error = false
    pubsub = pubsub_config

    subscription = pubsub.subscription(subscription_name)
    @subscriber = subscription.listen { |received_message|
      msg_data = begin
                   JSON.parse(received_message.data)
                 rescue
                   {}
                 end
      if handle_exception
        begin
          acknowledge = yield(msg_data, received_message.message_id)
          received_message.acknowledge! if acknowledge
        rescue PG::ConnectionBad, ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid, ActiveRecord::ConnectionTimeoutError => e
          logger.error "Listener => #{subscription_name.inspect}  => DB Error => " + e.inspect
          @running = false
          @database_error = true
        rescue => e
          logger.error "Listener => #{subscription_name.inspect}  => " + e.inspect
        end
      else
        acknowledge = yield(msg_data, received_message.message_id)
        received_message.acknowledge! if acknowledge
      end
    }
    @subscriber.start
    puts "#{subscription_name} Started Async"
    while @running
      sleep(5)
    end
    @subscriber.stop.wait!
  end

  def stop
    puts "TERM Received"
    @running = false
  end
end
