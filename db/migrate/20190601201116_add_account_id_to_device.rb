class AddAccountIdToDevice < ActiveRecord::Migration[5.2]
  def change
    remove_reference :devices, :account, index: true
    add_reference :devices, :account, index: true, type: :uuid
  end
end
