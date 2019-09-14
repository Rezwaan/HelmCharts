class Admin::AssetsController < Admin::ApplicationController
  def upload_signed_url
    authorize [:assets, :asset]

    path = Assets::AssetService.new.signed_url(signed_url_params.to_h.symbolize_keys)

    return render json: {error: "error"}, status: :unprocessable_entity unless path

    render json: path, status: :ok
  end

  private

  def signed_url_params
    params.permit(:upload_path, :content_type)
  end
end
