# == Schema Information
#
# Table name: countries
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Countries::Country < ApplicationRecord
  include Common::Helpers::CurrencyHelper
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]
  scope :by_coordinates, ->(lat, lng) { where("ST_Intersects(countries.geom,ST_POINT(?, ?))", lng.to_f, lat.to_f) }
end
