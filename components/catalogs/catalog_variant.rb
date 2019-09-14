# == Schema Information
#
# Table name: catalog_variants
#
#  id                 :uuid             not null, primary key
#  catalog_key        :string           not null
#  deleted_at         :datetime
#  end_at_minutes     :integer
#  name               :string
#  priority           :integer          default(0)
#  start_from_minutes :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  catalog_id         :uuid
#
# Indexes
#
#  index_catalog_variants_on_catalog_id   (catalog_id)
#  index_catalog_variants_on_catalog_key  (catalog_key)
#

class Catalogs::CatalogVariant < ApplicationRecord
  belongs_to :catalog, class_name: "Catalogs::Catalog"

  validates :name, :catalog_key, :start_from_minutes, :end_at_minutes, presence: true
  validate :valid_time_range

  scope :not_deleted, -> { where(deleted_at: nil) }

  def self.policy
    Catalogs::CatalogVariantPolicy
  end

  private

  def valid_time_range
    if start_from_minutes >= end_at_minutes
      errors.add(:time_range, "start time must be less than end time")
    end
  end
end
