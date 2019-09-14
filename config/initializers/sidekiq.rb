require "sidekiq"
require "sidekiq/web"
require "sidekiq/cron/web"

module Sidekiq
  module Logging
    # override existing log to include the arguments passed to `perform`
    def self.job_hash_context(job_hash)
      klass = job_hash["wrapped"] || job_hash["class"]
      bid = job_hash["bid"]
      args = job_hash["args"]
      "#{klass} ARGS-#{args} JID-#{job_hash["jid"]} BID-#{bid}"
    end
  end
end

Encoding.default_external = Encoding::UTF_8

Sidekiq.configure_server do |config|
  config.redis = {
    url: Rails.application.secrets.sidekiq[:redis_uri],
    id: nil,
  }

  # https://github.com/mperham/sidekiq/wiki/Pro-Reliability-Server
  config.super_fetch!

  # https://github.com/mperham/sidekiq/wiki/Logging
  # config.log_formatter = Sidekiq::Logger::Formatters::JSON.new

  schedule_file = "#{Rails.root}/config/schedule.yml.erb"
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.safe_load(ERB.new(File.read(schedule_file)).result)
  end

  # Configure prometheus
  if ENV.fetch("PROMETHEUS_ENABLED", false)
    config.on :startup do
      require "prometheus_exporter/instrumentation"
      PrometheusExporter::Instrumentation::Process.start type: "sidekiq"
    end

    config.server_middleware do |chain|
      require "prometheus_exporter/instrumentation"
      chain.add PrometheusExporter::Instrumentation::Sidekiq
    end

    at_exit do
      PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
    end

    config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: Rails.application.secrets.sidekiq[:redis_uri], id: nil}
  config.client_middleware do |chain|
    chain.add Common::Sidekiq
  end
end

# https://github.com/mperham/sidekiq/wiki/Pro-Reliability-Client
Sidekiq::Client.reliable_push! unless Rails.env.test?

if Rails.env.production?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # Protect against timing attacks:
    # - See https://codahale.com/a-lesson-in-timing-attacks/
    # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
    # - Use & (do not use &&) so that it doesn't short circuit.
    # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(Rails.application.secrets.sidekiq[:username])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(Rails.application.secrets.sidekiq[:password]))
  end
end
