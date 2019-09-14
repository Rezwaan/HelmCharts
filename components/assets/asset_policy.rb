class Assets::AssetPolicy < ApplicationPolicy
  def upload_signed_url?
    user.admin? || user.content_entry?
  end
end
