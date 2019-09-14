class LiteApp::Presenter::Devices::Me
  def initialize(device:, account: nil)
    @device = device
    @account = account
    @app_version = AppVersions::AppVersionService.new.fetch(id: @device.app_version_id) if @device&.app_version_id
  end

  def present
    data = {
      id: @device.id,
      account: @account,
      order_refresh_secs: (Rails.application.secrets.order_refresh_secs || 20).to_i,
      zendesk: zendesk,
    }
    data.merge({'app_update': app_update_data})
  end

  def app_update_data
    return nil if @app_version.blank? || @app_version.update_action.to_s == "no_update" || (Rails.application.secrets.app_versions[:device_usage_enabled] && @app_version.update_action.to_s == "recommended" && ((@device.device_usage % update_dialog_frequency) != 0))
    {
      update_action: @app_version.update_action,
      app_store_url: @app_version.app_store_url,
      title: I18n.t("app_versions.#{@app_version.device_type}.title", default: I18n.t("app_versions.title")),
      message: I18n.t("app_versions.#{@app_version.device_type}.body", default: I18n.t("app_versions.body")),
      update_button_title: I18n.t("app_versions.#{@app_version.device_type}.actions.update", default: I18n.t("app_versions.actions.update")),
      skip_button_title: @app_version.update_action.to_s == "recommended" ? I18n.t("app_versions.#{@app_version.device_type}.actions.skip", default: I18n.t("app_versions.actions.skip")) : nil,
      home_alert_message: I18n.t("app_versions.#{@app_version.device_type}.messages.home_alert", default: I18n.t("app_versions.messages.home_alert")),
    }
  end

  def update_dialog_frequency
    frequency = (Rails.application.secrets.app_versions || {})[:recommended_frequency].to_i
    frequency <= 0 ? 1 : frequency
  end

  def zendesk
    {
      'app_id': (Rails.application.secrets.zendesk || {})[:app_id],
      'client_id': (Rails.application.secrets.zendesk || {})[:app_client_id],
      'url': (Rails.application.secrets.zendesk || {})[:url],
      'subdomain': (Rails.application.secrets.zendesk || {})[:url],
      'chat_token': (Rails.application.secrets.zendesk || {})[:chat_token],
      'token': @account ? Zendesk::ZendeskTicketService.new.generate_token(creator_type: Accounts::Account.name, creator_id: @account["id"]) : nil,
    }
  end
end
