class Notifications::Firebase::Notifier
  include ::HTTParty

  URL = "https://fcm.googleapis.com/v1/projects/%{project_name}/messages:send"

  def push(to:, priority: "normal", message: {}, collapse_key: nil, time_to_live: "86400")
    return {"error" => "validation error", "request" => {to: to.to_s, message: message}} unless Notifications::Firebase::Message.valid?(to: to, message: message)
    priority = ensure_priority(priority)
    body = {"message" => {}}
    body["message"]["token"] = to.to_s
    # NEED TO SEND NOTIFICATION INSIDE APPLE AND ANDROID DATA RATHER THAN SENDING OUTSIDE
    # body["message"]["notification"] = message["notification"] if message["notification"].present?
    body["message"]["data"] = message["data"] if message["data"].present?
    body["message"]["apns"] = {}
    body["message"]["android"] = {}
    body["message"]["apns"]["payload"] = {"aps" => {"alert" => message["notification"], :sound => message["sound"] || "default"}} if message["notification"].present?
    if message["unique_id"].present?
      body["message"]["android"]["collapse_key"] = message["unique_id"]
      body["message"]["apns"]["headers"] = {"apns-collapse-id" => message["unique_id"]}
    end
    response = nil
    urls.each do |url|
      3.times do |_|
        response = send_notification(body: body, url: url)
        return response unless response && (response["retry"] || response["error"])
      end
    end
    response
  end

  private

  def send_notification(body:, url:)
    headers = {"Authorization" => get_auth_header.to_s, "Content-Type" => "application/json"}
    response = self.class.post(
      url,
      body: JSON.dump(body),
      headers: headers
    )
    normalize_response(response: response, request: body)
  end

  def normalize_response(response:, request:)
    if response.present? && response.code == 200
      JSON.parse response.body
    elsif response.present? && response.code == 401
      get_auth_header(true)
      {"retry" => true}
    else
      {"error" => response.code, "request" => request, "response" => response.body}
    end
  end

  def ensure_priority(priority)
    priority.in?(["normal", "high"]) ? priority : "normal"
  end

  def get_auth_header(reload = false)
    @@token ||= nil
    @@token = nil if reload
    unless @@token
      authorizer = Google::Auth::GCECredentials.new
      token = authorizer.fetch_access_token!
      @@token = "#{token["token_type"]} #{token["access_token"]}"
    end
    @@token
  end

  def urls
    @@urls ||= nil
    unless @@urls
      @@urls = [URL % {project_name: project_name}]
      @@urls.push(URL % {project_name: Rails.application.secrets.fcm_messages[:old_project_name]}) if Rails.application.secrets.fcm_messages[:old_project_name]
    end
    @@urls
  end

  def project_name
    @@project_name ||= (Rails.application.secrets.fcm_messages || {})[:project_name]
  end
end
