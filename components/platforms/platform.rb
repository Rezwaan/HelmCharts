# == Schema Information
#
# Table name: platforms
#
#  id         :bigint           not null, primary key
#  backend_id :string           not null
#  logo_url   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Platforms::Platform < ApplicationRecord
  validates :backend_id, presence: true

  translates :name, touch: true, fallbacks_for_empty_translations: true

  globalize_accessors locales: Locales::LocaleService.new.filter.pluck(:key), attributes: [:name]
end
