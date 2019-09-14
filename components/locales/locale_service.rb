module Locales
  class LocaleService
    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc", light: false)
      Locales::Locale.all.map { |locale| create_dto(locale) }
    end

    def fetch(id:)
      locale = Locales::Locale.find(id)
      return nil unless locale
      create_dto(locale)
    end

    def fetch_by_key(key:)
      locale = Locales::Locale.find_by_key(key)
      return nil unless locale
      create_dto(locale)
    end

    def default_locale_id
      Locales::Locale.default&.id
    end

    def default_locale
      create_dto(Locales::Locale.default)
    end

    private

    def create_dto(locale)
      return nil unless locale
      Locales::LocaleDTO.new(
        id: locale.id,
        key: locale.key,
        name: locale.name,
        rtl: locale.rtl
      )
    end
  end
end
