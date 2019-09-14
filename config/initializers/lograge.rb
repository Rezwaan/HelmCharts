require "lograge/sql/extension"

Rails.application.configure do
  config.lograge.enabled = true unless Rails.env.test?
  config.colorize_logging = false

  config.lograge.base_controller_class = ActionController::API.name

  # Do not log status requests
  config.lograge.ignore_actions = %w[StatusesController#liveness StatusesController#readiness StatusesController#status]

  # Use JSON format
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_payload do |controller|
    account = controller.current_account if controller.respond_to? :current_account

    {
      current_account_id: account&.try(:id),
      current_account_username: account&.try(:username),
    }
  end

  config.lograge.custom_options = lambda do |e|
    opts = {time: Time.now}
    exceptions = %w[controller action format id]
    opts[:params] = e.payload[:params].except(*exceptions)
    opts[:cf_ray] = e.payload[:headers]["CF-Ray"] || "UNDEFINED" if Rails.env.production?
    opts
  end

  config.lograge_sql.extract_event = proc do |e|
    {
      name: e.payload[:name],
      duration: e.duration.to_f.round(2),
      sql: e.payload[:sql],
    }
  end
end
