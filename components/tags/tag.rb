# == Schema Information
#
# Table name: tags
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Tags::Tag < ApplicationRecord
  translates :name, touch: true, fallbacks_for_empty_translations: true
  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]

  scope :by_name, ->(name) {
                    joins(:translations)
                      .where("tag_translations.name ILIKE ?",
                      "%#{name}%").distinct
                  }
end
