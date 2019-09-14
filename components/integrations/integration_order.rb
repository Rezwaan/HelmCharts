# == Schema Information
#
# Table name: integration_orders
#
#  id                  :uuid             not null, primary key
#  external_data       :jsonb
#  external_reference  :string
#  last_synced_at      :datetime         not null
#  status              :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  integration_host_id :uuid
#  order_id            :bigint
#
# Indexes
#
#  index_integration_orders_on_integration_host_id  (integration_host_id)
#  index_integration_orders_on_order_id             (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (integration_host_id => integration_hosts.id)
#  fk_rails_...  (order_id => orders.id)
#

class Integrations::IntegrationOrder < ApplicationRecord
  belongs_to :integration_host, class_name: Integrations::IntegrationHost.name
  belongs_to :order, class_name: Orders::Order.name
  delegate :phone_number, to: :order

  enum status: {
    pending: 1,
    finalized: 2,
    expired: 3,
  }

  def self.policy
    Integrations::IntegrationOrderPolicy
  end
end
