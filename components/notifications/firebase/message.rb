class Notifications::Firebase::Message
  module Type
    NOTIFICATION = 1
    DATA = 2
    HYBRID = 3
  end

  def self.message(language: :en)
    {}.merge(collapse_key).merge(priority).merge(time_to_live).merge(notification).merge(data)
  end

  def self.valid?(to: "only check the message", message: self.message)
    return false if to.blank? || message.blank? || (message["data"].blank? && message["notification"].blank?)

    valid_data?(data: message["data"]) && vaild_notification?(notification: message["notification"])
  end

  # private class methods
  def self.data
    {}
  end

  def self.notification
    return {} if @type == Type::DATA

    {
      "notification" => {
        "title" => @notification_title,
        "body" => @notification_body,
      }.merge(notification_sound).merge(notification_color),
    }
  end

  def self.collapse_key(id: nil)
    return {} unless @collapse_key.present?

    {
      "collapse_key" => @collapse_key % {id: id},
    }
  end

  def self.unique_id(id: nil, options: {})
    return {} unless @unique_id.present?

    extras = options[:collapse_key].present? ? "_#{options[:collapse_key]}" : ""
    {
      "unique_id" => @unique_id % {id: id, extras: extras},
    }
  end

  def self.priority
    return {} unless @priority.present?

    {
      priority: @priority,
    }
  end

  def self.time_to_live
    return {} unless @life_time.present?

    {
      time_to_live: @life_time,
    }
  end

  def self.notification_sound
    return {} unless @sound.present?

    {
      sound: @sound,
    }
  end

  def self.notification_color
    return {} unless @color.present?

    {
      color: @color,
    }
  end

  def self.valid_data?(data:)
    data.present? ? data.is_a?(Hash) : true
  end

  def self.vaild_notification?(notification:)
    notification.present? ? notification.is_a?(Hash) && notification["title"].present? && notification["body"].present? : true
  end

  def self.deeplink(app_name:)
    Rails.application.secrets.deeplinks[app_name] || "domeliteapp"
  end

  private_class_method :data, :notification, :collapse_key, :priority, :time_to_live, :notification_sound, :notification_color, :valid_data?, :vaild_notification?
end
