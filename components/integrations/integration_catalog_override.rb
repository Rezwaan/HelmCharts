# == Schema Information
#
# Table name: integration_catalog_overrides
#
#  id                     :uuid             not null, primary key
#  item_type              :string
#  properties             :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  integration_catalog_id :uuid
#  item_id                :string
#
# Indexes
#
#  index_integration_catalog_overrides_on_integration_catalog_id  (integration_catalog_id)
#  integration_catalog_overrides_item_id_uniqueness               (integration_catalog_id,item_type,item_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (integration_catalog_id => integration_catalogs.id)
#

class Integrations::IntegrationCatalogOverride < ApplicationRecord
  belongs_to :catalog, class_name: Integrations::IntegrationCatalog.name, foreign_key: :integration_catalog_id

  ITEM_TYPES = %w(
    bundle_sets
    bundles
    categories
    customization_ingredient_items
    customization_ingredients
    customization_option_items
    customization_options
    item_bundles
    item_sets
    items
    products
    sets
  )

  validates :properties, presence: true, length: { minimum: 1 }
  validates :item_id, presence: true
  validates :item_type, presence: true, inclusion: { in: ITEM_TYPES }
end
