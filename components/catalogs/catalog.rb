# == Schema Information
#
# Table name: catalogs
#
#  id          :uuid             not null, primary key
#  catalog_key :string           not null
#  deleted_at  :datetime
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  brand_id    :bigint
#
# Indexes
#
#  index_catalogs_on_brand_id  (brand_id)
#
# Foreign Keys
#
#  fk_rails_...  (brand_id => brands.id)
#

class Catalogs::Catalog < ApplicationRecord
  belongs_to :brand, class_name: "Brands::Brand"
  has_many :catalog_variants, class_name: "Catalogs::CatalogVariant"

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :by_id, ->(id) { where(id: id) }
  scope :by_brand, ->(brand_ids) { where(brand_id: brand_ids) }
  scope :by_name, ->(name) { where("name ILIKE ?", "%#{name}%") }

  def self.policy
    Catalogs::CatalogPolicy
  end
end
