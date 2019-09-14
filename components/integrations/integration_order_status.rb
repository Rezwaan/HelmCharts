# == Schema Information
#
# Table name: integration_order_statuses
#
#  id                   :uuid             not null, primary key
#  external_data        :jsonb
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  integration_order_id :uuid
#
# Indexes
#
#  index_integration_order_statuses_on_integration_order_id  (integration_order_id)
#
# Foreign Keys
#
#  fk_rails_...  (integration_order_id => integration_orders.id)
#

module Integrations
  class IntegrationOrderStatus < ApplicationRecord
    belongs_to :integration_order, class_name: "Integrations::IntegrationOrder"
  end
end
