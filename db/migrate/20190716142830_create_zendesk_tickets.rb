class CreateZendeskTickets < ActiveRecord::Migration[5.2]
  def change
    create_table :zendesk_tickets do |t|
      t.string :zendesk_reference_id
      t.references :related_to, polymorphic: true
      t.references :ticket, foreign_key: true

      t.timestamps
    end
  end
end
