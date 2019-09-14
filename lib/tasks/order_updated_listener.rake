require "json"

namespace :order_updated_listener do
  desc "Order update listener"
  task run: :environment do
    listener = OrderReceivers::Platform::PubSub::UpdateListen.new(configuration: :order)
    Signal.trap("INT") do
      puts "INT Received"
      listener.stop
    end
    Signal.trap("TERM") do
      puts "TERM Received"
      listener.stop
    end
    begin
      listener.order_update
    rescue => e
      puts "Error on order_updated_listener => #{e.inspect}"
    end
  end
end
