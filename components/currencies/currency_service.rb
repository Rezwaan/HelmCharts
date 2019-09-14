module Currencies
  class CurrencyService
    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc", light: false)
      Currencies::Currency.all.map { |currency| create_dto(currency) }
    end

    def fetch(id:, locale: I18n.locale)
      currency = Currencies::Currency.find(id, locale)
      return nil unless currency
      create_dto(currency)
    end

    def fetch_by_key(key:, locale: I18n.locale)
      currency = Currencies::Currency.find_by_key(key, locale)
      return nil unless currency
      create_dto(currency)
    end

    def default_currency_id
      Currencies::Currency.all.first&.id
    end

    def default_currency
      create_dto(Currencies::Currency.all.first)
    end

    private

    def create_dto(currency)
      return nil unless currency
      Currencies::CurrencyDTO.new(
        id: currency.id,
        key: currency.key,
        name: currency.name,
        code: currency.code
      )
    end
  end
end
