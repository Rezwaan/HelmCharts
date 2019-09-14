# == Schema Information
#
# Table name: catalog_assignments
#
#  id              :uuid             not null, primary key
#  related_to_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  catalog_id      :uuid
#  related_to_id   :bigint
#
# Indexes
#
#  index_catalog_assignments_on_catalog_id                         (catalog_id)
#  index_catalog_assignments_on_related_to_type_and_related_to_id  (related_to_type,related_to_id)
#
# Foreign Keys
#
#  fk_rails_...  (catalog_id => catalogs.id)
#

class Catalogs::CatalogAssignment < ApplicationRecord
  belongs_to :catalog, class_name: Catalogs::Catalog.name

  def self.policy
    Catalogs::CatalogAssignmentPolicy
  end
end
