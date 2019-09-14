# == Schema Information
#
# Table name: products
#
#  id              :uuid             not null, primary key
#  default_price   :float
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  manufacturer_id :uuid
#  prototype_id    :uuid
#
# Indexes
#
#  index_products_on_manufacturer_id  (manufacturer_id)
#  index_products_on_prototype_id     (prototype_id)
#
# Foreign Keys
#
#  fk_rails_...  (manufacturer_id => manufacturers.id)
#  fk_rails_...  (prototype_id => prototypes.id)
#

class ProductCatalog::Product < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  translates :description, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name, :description]

  belongs_to :prototype, class_name: "ProductCatalog::Prototype"
  belongs_to :manufacturer, class_name: "ProductCatalog::Manufacturer"

  has_many :product_tags, class_name: "ProductCatalog::ProductTag"
  has_many :tags, class_name: "Tags::Tag", through: :product_tags
  has_many :variants, class_name: "ProductCatalog::Variant"

  scope :by_name, ->(name) {
                    joins(:translations)
                      .where("product_translations.name ILIKE ?",
                      "%#{name}%").distinct
                  }

  scope :by_prototype_name, ->(name) {
                              joins(prototype: :translations)
                                .where("prototype_translations.name ILIKE ?", "%#{name}%").distinct
                            }

  scope :by_manufacturer_name, ->(name) {
                                 joins(manufacturer: :translations)
                                   .where("manufacturer_translations.name ILIKE ?", "%#{name}%").distinct
                               }
end
