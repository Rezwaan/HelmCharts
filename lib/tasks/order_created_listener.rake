require "json"

namespace :order_created_listener do
  desc "Order created listener"
  task run: :environment do
    listener = OrderReceivers::Platform::PubSub::CreateListen.new(configuration: :order)
    Signal.trap("INT") do
      puts "INT Received"
      listener.stop
    end
    Signal.trap("TERM") do
      puts "TERM Received"
      listener.stop
    end
    begin
      listener.order_create
    rescue => e
      puts "Error on order_created_listener => #{e.inspect}"
    end
  end
end
