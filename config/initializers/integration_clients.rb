# rubocop:disable Style/GlobalVars
$kudu_sdm_client = ConnectionPool.new(size: 5, timeout: 5) {
  integration_host = Integrations::IntegrationHost.find_by!(name: "Kudu")

  Integrations::Sdm::Client.new(
    config: integration_host.config.with_indifferent_access,
  )
}
# rubocop:enable Style/GlobalVars
