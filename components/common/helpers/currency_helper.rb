module Common::Helpers::CurrencyHelper
  def currency
    Currencies::CurrencyService.new.fetch(id: currency_id)
  end
end
