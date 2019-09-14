# == Schema Information
#
# Table name: integration_stores
#
#  id                  :uuid             not null, primary key
#  enabled             :boolean          default(TRUE), not null
#  external_data       :jsonb
#  external_reference  :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  integration_host_id :uuid
#  store_id            :bigint
#
# Indexes
#
#  index_integration_stores_on_integration_host_id  (integration_host_id)
#  index_integration_stores_on_store_id             (store_id) UNIQUE
#  integration_stores_external_reference_uniqness   (integration_host_id,external_reference) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (integration_host_id => integration_hosts.id)
#  fk_rails_...  (store_id => stores.id)
#

class Integrations::IntegrationStore < ApplicationRecord
  belongs_to :integration_host, class_name: Integrations::IntegrationHost.name
  belongs_to :store, class_name: Stores::Store.name, optional: true

  validates :store_id, uniqueness: true, allow_nil: true

  scope :by_id, ->(id) { where(id: id) }
  scope :by_store_name, ->(name) {
    joins(store: :translations).where("store_translations.name ILIKE ?", "%#{name}%")
  }
  scope :by_integration_host_name, ->(name) {
    joins(:integration_host).where("integration_hosts.name ILIKE ?", "%#{name}%")
  }

  def self.policy
    Integrations::IntegrationStorePolicy
  end
end
