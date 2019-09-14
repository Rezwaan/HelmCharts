class Assets::AssetService
  attr_reader :asset_service

  def initialize
    @asset_service = Assets::Client.new
  end

  def signed_url(upload_path:, content_type:)
    return if upload_path.blank? || content_type.blank?

    asset_service.get_image_upload_url(upload_path: upload_path, content_type: content_type)
  end
end
