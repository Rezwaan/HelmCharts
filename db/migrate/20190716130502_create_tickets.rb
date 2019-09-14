class CreateTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :tickets do |t|
      t.integer :ticket_type, null: false, index: true
      t.jsonb :data, null: false, default: {}
      t.references :related_to, polymorphic: true, index: true, type: :uuid
      t.references :creator, polymorphic: true, null: false, index: true, type: :uuid

      t.timestamps
    end
  end
end
