class AddReferenceCountryToBrands < ActiveRecord::Migration[5.2]
  def change
    add_reference :brands, :country, foreign_key: true
  end
end
