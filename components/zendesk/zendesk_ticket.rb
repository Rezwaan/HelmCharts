# == Schema Information
#
# Table name: zendesk_tickets
#
#  id                   :bigint           not null, primary key
#  related_to_type      :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  related_to_id        :bigint
#  ticket_id            :bigint
#  zendesk_reference_id :string
#
# Indexes
#
#  index_zendesk_tickets_on_related_to_type_and_related_to_id  (related_to_type,related_to_id)
#  index_zendesk_tickets_on_ticket_id                          (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (ticket_id => tickets.id)
#

class Zendesk::ZendeskTicket < ApplicationRecord
  validates :related_to_type, :related_to_id, presence: true
end
