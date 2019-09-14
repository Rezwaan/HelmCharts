class AddColumnRejectReasonToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :reject_reason, index: true
  end
end
