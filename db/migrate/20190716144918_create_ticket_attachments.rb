class CreateTicketAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :ticket_attachments, id: :uuid do |t|
      t.references :ticket, foreign_key: true
      t.attachment :file_attachment

      t.timestamps
    end
  end
end
