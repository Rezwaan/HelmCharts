class CreateRushDeliveries < ActiveRecord::Migration[5.2]
  def change
    create_enum :rush_delivery_status, %w[unassigned assigned
                                          enroute_to_branch at_the_branch picked_up enroute_to_customer delivered
                                          canceled failed_to_assign near_pick_up near_delivery left_pick_up
                                          pre_assigned returned waiting_pickup_confirmation pickup_confirmed
                                          at_delivery left_delivery]

    create_table :rush_deliveries, id: :uuid do |t|
      t.decimal :drop_off_longitude, null: false, precision: 10, scale: 6
      t.decimal :drop_off_latitude, null: false, precision: 10, scale: 6
      t.text :drop_off_description, null: false
      t.decimal :pick_up_latitude, null: false, precision: 10, scale: 6
      t.decimal :pick_up_longitude, null: false, precision: 10, scale: 6
      t.references :order, null: false, foreign_key: true, unique: true, index: true
      t.timestamps
      t.enum :status, enum_name: :rush_delivery_status, default: "unassigned"
    end
  end
end
