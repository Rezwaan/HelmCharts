class AddCountryIdInCompany < ActiveRecord::Migration[5.2]
  def change
    add_reference :companies, :country, index: true
  end
end
