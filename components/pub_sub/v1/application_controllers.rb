class PubSub::V1::ApplicationController < ApplicationController
  before_action :authenticate!
  before_action :unpack

  def authenticate
    # @TODO: Implement Authentication
  end

  def unpack
    @message_id = params[:message][:messageId]
    plain_data = Base64.decode64(params[:message][:data])
    Rails.logger.debug "#{@message_id} => #{plain_data}"
    @data = JSON.parse(plain_data)
    @payload = @data["payload"] || {}
  end
end
