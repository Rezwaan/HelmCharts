class AddCompanyReferencesInBrand < ActiveRecord::Migration[5.2]
  def change
    add_reference :brands, :company, type: :uuid, index: true
  end
end
