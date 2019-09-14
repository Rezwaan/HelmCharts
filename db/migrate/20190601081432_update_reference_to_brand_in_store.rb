class UpdateReferenceToBrandInStore < ActiveRecord::Migration[5.2]
  def change
    remove_reference :stores, :brand, index: true
    add_reference :stores, :brand, index: true, type: :uuid
  end
end
