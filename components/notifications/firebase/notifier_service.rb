require "concurrent"
module Notifications::Firebase
  class NotifierService
    include Concurrent::Async

    def initialize(account_ids:)
      @devices = Devices::DeviceService.new.notifiable_devices(account_ids: account_ids) if account_ids.present?
      @devices ||= []
    end

    def order_updated(id:, payload: {}, options: {})
      send_messages do |device|
        Notifications::Firebase::Messages::OrderUpdatedMessage.messages(order_id: id, payload: payload, language: device.language, options: options)
      end
    end

    private

    def send_message(message:, device:)
      response = Notifications::Firebase::Firebase.send_message(device: device, message: message)
      if ((response["results"] || [])[0] || {})["error"].present?
        return {device.id => "Error: " + response["results"][0]["error"]}
      else
        return {device.id => "succeed"}
      end
    rescue => e
      {device.id => "Error: #{e.message}"}
    end

    def send_messages
      response = {}
      @devices.each do |device|
        if device["fcm_token"].nil?
          response[device.id] = "Error: device doesn't have fcm_token"
          next
        end
        messages = yield(device)
        if messages.blank?
          response[device.id] = "Message not generated"
          next
        end

        response.merge!(send_message(message: messages, device: device))
      end
      response
    end
  end
end
