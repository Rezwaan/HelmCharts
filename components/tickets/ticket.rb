# == Schema Information
#
# Table name: tickets
#
#  id              :bigint           not null, primary key
#  creator_type    :string           not null
#  data            :jsonb            not null
#  related_to_type :string
#  ticket_type     :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  creator_id      :uuid             not null
#  related_to_id   :uuid
#
# Indexes
#
#  index_tickets_on_creator_type_and_creator_id        (creator_type,creator_id)
#  index_tickets_on_related_to_type_and_related_to_id  (related_to_type,related_to_id)
#  index_tickets_on_ticket_type                        (ticket_type)
#

class Tickets::Ticket < ApplicationRecord
  belongs_to :creator, polymorphic: true
  belongs_to :related_to, polymorphic: true
  has_many :ticket_attachments, class_name: "Tickets::TicketAttachment"

  validates :ticket_type, :creator_id, :creator_type, presence: true
  validates :ticket_type, inclusion: {in: Tickets::Core.creatable_ticket_types_enum.keys}
  validates :creator, presence: {message: "the creator doesn't exist!"}
  validate :data_valid?

  accepts_nested_attributes_for :ticket_attachments, allow_destroy: true

  enum ticket_type: Tickets::Core.all_ticket_types_enum

  scope :by_ticket_type, ->(ticket_type) { where("tickets.ticket_type =? ", ticket_type) }
  scope :by_order_id, ->(id) { where("tickets.related_to_id =? and tickets.related_to_type = 'Orders::Order'", id) }
  scope :by_creator_type, ->(creator_type) { where("tickets.creator_type =? ", creator_type) }

  def ticket_type=(val)
    write_attribute :ticket_type, val.to_i.abs
  end

  def self.related_to_types
    [Orders::Order, Accounts::Account]
  end

  def data_valid?
    ticket_type = Tickets::Core.all_ticket_types[Tickets::Ticket.ticket_types[self.ticket_type]]
    ticket_type.is_data_valid?(data, errors)
  end
end
