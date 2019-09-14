class PubSub::SyncListener < PubSub::PubSub
  def pull(subscription_name:, logger: Rails.logger, handle_exception: true, continuous: false)
    @running = true
    @database_error = false
    pubsub = pubsub_config

    subscription = pubsub.subscription(subscription_name)
    puts "#{subscription_name} Started Sync"
    if continuous
      while @running
        subscription.pull.each do |received_message|
          break unless @running
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
        end
        sleep(sleep_in_sync_listen) if sleep_in_sync_listen > 0
      end
    else
      subscription.pull.each do |received_message|
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
      end
    end
  end

  def stop
    puts "TERM Received"
    @running = false
  end

  def sleep_in_sync_listen
    @sleep_in_sync_listen ||= Rails.application.secrets.pub_sub.dig(:sleep_in_sync_listen).to_f
  end
end
