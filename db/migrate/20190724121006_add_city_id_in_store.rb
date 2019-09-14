class AddCityIdInStore < ActiveRecord::Migration[5.2]
  def change
    add_reference :stores, :city, index: true
  end
end
