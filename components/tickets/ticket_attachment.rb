# == Schema Information
#
# Table name: ticket_attachments
#
#  id                           :uuid             not null, primary key
#  file_attachment_content_type :string
#  file_attachment_file_name    :string
#  file_attachment_file_size    :bigint
#  file_attachment_updated_at   :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  ticket_id                    :bigint
#
# Indexes
#
#  index_ticket_attachments_on_ticket_id  (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (ticket_id => tickets.id)
#

class Tickets::TicketAttachment < ApplicationRecord
  belongs_to :ticket, class_name: "Tickets::Ticket"
  has_attached_file :file_attachment
  validates_attachment :file_attachment, size: {in: 0..10.megabytes}
  do_not_validate_attachment_file_type :file_attachment
end
