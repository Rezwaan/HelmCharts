class CreateOrderNotes < ActiveRecord::Migration[5.2]
  def change
    create_table :order_notes, id: :uuid do |t|
      t.references :order, foreign_key: true
      t.text :note
      t.integer :note_type
      t.string :author_category
      t.string :author_entity

      t.timestamps
    end
  end
end
