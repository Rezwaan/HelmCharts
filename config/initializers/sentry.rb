Raven.configure do |config|
  config.dsn = Rails.application.secrets.services&.dig(:sentry, :dsn) || ""
  config.current_environment = Rails.application.secrets.services&.dig(:sentry, :app_env) || "undefined"
  config.excluded_exceptions += []
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.silence_ready = true
  config.release = Rails.configuration.app_release
  config.app_dirs_pattern = /(app|bin|components|config|db|lib|test)/
end
