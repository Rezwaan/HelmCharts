class AddCompanyReferencesInStore < ActiveRecord::Migration[5.2]
  def change
    add_reference :stores, :company, type: :uuid, index: true
  end
end
