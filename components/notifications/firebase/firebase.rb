class Notifications::Firebase::Firebase
  def self.send_message(device:, message: {})
    reciever = device.fcm_token
    priority = message[:priority] || "high"
    collapse_key = message[:collapse_key]
    time_to_live = message[:time_to_live]

    result = notifier(device: device).push(to: reciever, priority: priority, message: message, collapse_key: collapse_key, time_to_live: time_to_live)
    logger = Rails.logger || Logger.new(STDOUT)
    logger.debug "Notifier::Firebase for order #{result}"
    if result.blank? || result["error"].present?
      handle_error(result: result, device: device)
    else
      handle_response(result: result, device: device)
    end
    result
  end

  def self.notifier(device: nil)
    Notifications::Firebase::Notifier.new
  end

  def self.handle_response(result:, device:)
    if result["failure"] == 0
      if result["canonical_ids"] != 0 && result["results"].first["registration_id"].present?
        # TODO do something about new fcm token
      end
    end
    result
  end

  def self.handle_error(result:, device:)
    Devices::DeviceService.new.mark_fcm_invalid(id: device.id) if result["error"] ==  404

    raise result.to_s
  end
end
