class LiteApp::Api::V1::DevicesController < LiteApp::Api::V1::ApplicationController
  skip_before_action :authenticate!, only: [:register]
  skip_before_action :authorize!, only: [:register, :me, :login, :update]

  def register
    params[:last_opened_ip] = params[:created_ip] = request.remote_ip
    device = Devices::DeviceService.new.register(attributes: device_register_params)

    return render json: device, status: :unprocessable_entity if device.blank? || device.is_a?(ActiveModel::Errors)

    render json: device
  end

  def update
    params[:last_opened_ip] = request.remote_ip
    device = Devices::DeviceService.new.update(
      id: @current_device.id,
      attributes: device_update_params,
      check_version: true,
    )

    return render json: device, status: :unprocessable_entity if device.blank? || device.is_a?(ActiveModel::Errors)

    render json: device
  end

  def verify
  end

  def me
    render json: LiteApp::Presenter::Devices::Me.new(account: @current_account, device: @current_device).present
    Devices::DeviceService.new.device_opened(id: @current_device.id, ip: request.remote_ip)
    Devices::DeviceService.new.increment_counter(id: current_device.id)
  end

  def login
    device_service = Devices::DeviceService.new
    account_service = Accounts::AccountService.new
    account = account_service.authenticate_account(username: params[:username], password: params[:password])

    return render json: {error: "Username/Password does'nt match."}, status: :unauthorized unless account

    device_service.update(id: @current_device[:id], attributes: {account_id: account[:id]})
    render json: LiteApp::Presenter::Devices::Me.new(account: account, device: @current_device).present
  end

  def logout
    device_service = Devices::DeviceService.new
    device_service.update(id: @current_device[:id], attributes: {account_id: nil})
    render json: LiteApp::Presenter::Devices::Me.new(account: nil, device: @current_device).present
  end

  private

  def device_register_params
    params.permit(:installation_uid, :last_opened_ip, :created_ip, :device_type,
      :os, :idfa, :idfv, :mac, :android_id, :gps_adid, :imei, :fcm_token,
      :gcm_token, :apn_token, :enable_notifications, :language, :app_version,
      :device_manufacturer, :device_model, :keep_service_alive, :draw_overlay, :app_name, :build_number)
  end

  def device_update_params
    params.permit(:last_opened_ip, :os, :idfa, :idfv, :android_id, :gps_adid,
      :imei, :fcm_token, :gcm_token, :apn_token, :enable_notifications,
      :language, :app_version, :keep_service_alive, :draw_overlay, :app_name, :build_number)
  end
end
