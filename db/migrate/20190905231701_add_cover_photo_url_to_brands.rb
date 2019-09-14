class AddCoverPhotoUrlToBrands < ActiveRecord::Migration[5.2]
  def change
    add_column :brands, :cover_photo_url, :string
  end
end
