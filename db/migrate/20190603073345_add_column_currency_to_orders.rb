class AddColumnCurrencyToOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :currency, index: true
  end
end
