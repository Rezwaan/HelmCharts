# == Schema Information
#
# Table name: integration_catalogs
#
#  id                  :uuid             not null, primary key
#  external_data       :jsonb
#  external_reference  :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  catalog_id          :uuid
#  integration_host_id :uuid
#
# Indexes
#
#  index_integration_catalogs_on_catalog_id           (catalog_id)
#  index_integration_catalogs_on_integration_host_id  (integration_host_id)
#  integration_catalogs_external_reference_uniqness   (integration_host_id,external_reference) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (catalog_id => catalogs.id)
#  fk_rails_...  (integration_host_id => integration_hosts.id)
#

class Integrations::IntegrationCatalog < ApplicationRecord
  has_many :overrides, class_name: Integrations::IntegrationCatalogOverride.name
  belongs_to :integration_host, class_name: Integrations::IntegrationHost.name
  belongs_to :catalog, class_name: Catalogs::Catalog.name, optional: true

  scope :by_id, ->(id) { where(id: id) }
  scope :by_catalog_name, ->(name) { joins(:catalog).where("catalogs.name ILIKE ?", "%#{name}%") }
  scope :by_integration_host_name, ->(name) {
    joins(:integration_host).where("integration_hosts.name ILIKE ?", "%#{name}%")
  }

  def self.policy
    Integrations::IntegrationCatalogPolicy
  end
end
