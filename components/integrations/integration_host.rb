# == Schema Information
#
# Table name: integration_hosts
#
#  id               :uuid             not null, primary key
#  config           :jsonb
#  enabled          :boolean          default(TRUE), not null
#  integration_type :integer
#  name             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Integrations::IntegrationHost < ApplicationRecord
  has_many :integration_stores, class_name: Integrations::IntegrationStore.name
  has_many :integration_orders, class_name: Integrations::IntegrationOrder.name
  has_many :integration_catalogs, class_name: Integrations::IntegrationCatalog.name

  validates :name, :config, :integration_type, presence: true
  validates :name, uniqueness: {case_sensitive: false}

  enum integration_type: {
    pizzagest: 1,
    br: 2,
    sdm: 3,
    shawarmer: 4,
    foodics: 5,
    romansiah: 6,
  }

  def self.policy
    Integrations::IntegrationHostPolicy
  end
end
