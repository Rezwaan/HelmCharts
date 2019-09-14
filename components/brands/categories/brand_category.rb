# == Schema Information
#
# Table name: brand_categories
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_brand_categories_on_key  (key) UNIQUE
#

class Brands::Categories::BrandCategory < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  translates :plural_name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name, :plural_name]

  def self.policy
    Brands::Categories::BrandCategoryPolicy
  end
end
