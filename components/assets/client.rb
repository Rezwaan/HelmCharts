# A client for our assets API. Documentation is available at:
# https://www.notion.so/themakersteam/Assets-API-7060545569804872bcea4e62cee9f92a
#
# TODO: Turn this into a ruby gem for the assets API
class Assets::Client
  def initialize
    assets_api_config = Rails.application.secrets.assets_api
    api_url = assets_api_config[:url]
    api_token = assets_api_config[:token]

    @http_client = Faraday.new(api_url)
    @http_client.authorization("Bearer", api_token)
  end

  # Fetches an image and then request assets API to upload image to path, will
  # not upload if fetching the image returns anything other than HTTP 200
  #
  # @return [String, nil] Object URL or or nil
  def request_image_upload(image_url:, upload_path:)
    return nil unless image_exists?(image_url: image_url)

    response = @http_client.post("UploadImage", {
      object_path: upload_path,
      image_url: image_url,
    })

    return nil unless response.success?

    parsed_response = JSON.parse(response.body)
    parsed_response.dig("object_url")
  end

  # This endpoint generates a signed Google Cloud Storage URL that can be used for uploading the file.
  #
  # @return [String, nil] [signed_url, object_url]
  def get_image_upload_url(upload_path:, content_type:)
    response = @http_client.post("GetUploadURL", {
      object_path: upload_path,
      content_type: content_type
    })

    return unless response.success?

    JSON.parse(response.body)
  end

  # Gets the image display URL for the specified upload path, optionally specify
  # width and height as integers
  #
  # @return [String, nil] An image URL or nil
  def get_image_display_url(upload_path:, width: nil, height: nil)
    params = {
      object_path: upload_path,
    }

    params[:w] = width if width
    params[:h] = height if height

    response = @http_client.post("GetDisplayURL", params)

    return nil unless response.success?

    parsed_response = JSON.parse(response.body)

    parsed_response.dig("signed_url")
  end

  private

  # Makes a request to check that an image exists.
  # Meant to be used before requesting image upload to terminate early if an
  # image does not exist
  #
  # @return [Boolean] Whether the image exists or not (returns HTTP 200)
  def image_exists?(image_url:)
    # We don't use HTTP client here because we're not making a request to the
    # assets API

    # HACK: Disable verifying SSL because providers like Kudu allow their HTTPS
    # certificates to expire and we don't want that to get in the way of
    # scraping images
    connection = Faraday.new(image_url, ssl: {verify: false}) {|faraday|
      faraday.use FaradayMiddleware::FollowRedirects, limit: 3
      faraday.adapter :net_http
    }
    response = connection.get

    response.success?
  end
end
