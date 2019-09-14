class Notifications::Firebase::Messages::OrderUpdatedMessage < Notifications::Firebase::Message
  @type = Type::HYBRID
  @priority = "high"
  @sound = "enabled"
  @color = "#FFFF33"
  @notification_title = "notifications.firebase.messages.order_updated.title"
  @notification_body = "notifications.firebase.messages.order_updated.body"
  @collapse_key = "order_%{id}"
  @unique_id = "order_%{id}%{extras}"
  @life_time = "86400"

  def self.messages(order_id:, payload:, language:, options: {})
    {}.merge(unique_id(id: order_id, options: options)).merge(priority).merge(time_to_live)
      .merge(notification(order_id: order_id, language: language))
      .merge(data(order_id: order_id, language: language, payload: payload, deeplink: deeplink(app_name: :dome_lite)))
  end

  def self.notification(order_id:, language:)
    {
      "notification" => {
        "title" => I18n.t(@notification_title, {locale: language}),
        "body" => I18n.t(@notification_body, {locale: language}),
      },
    }
  end

  def self.data(order_id:, language:, payload: {}, deeplink:)
    {
      "data" => {
        :uri => "#{deeplink}://?screen=order&id=#{order_id}#{"&#{payload.to_query}" if payload.present?}",
        "title" => I18n.t(@notification_title, {locale: language}),
        "body" => I18n.t(@notification_body, {locale: language}),
        :screen => "order",
        :id => order_id.to_s,
      }.merge(payload.present? ? payload : {}),
    }
  end

  private

  private_class_method :notification, :data
end
