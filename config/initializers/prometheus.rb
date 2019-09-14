if ENV.fetch("PROMETHEUS_ENABLED", false)
  require "prometheus_exporter/client"
  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: ENV.fetch("PROMETHEUS_HOST", "0.0.0.0"),
    port: ENV.fetch("PROMETHEUS_PORT", PrometheusExporter::DEFAULT_PORT)
  )

  require "prometheus_exporter/instrumentation"
  PrometheusExporter::Instrumentation::Process.start(type: "master")
end
