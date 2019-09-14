class Currencies::Currency < Struct.new(:id, :key, :name, :code)
  CURRENCIES = [
    {id: 1, key: :sar, code: "SAR"},
    {id: 2, key: :bhd, code: "BHD"},
    {id: 3, key: :pkr, code: "PKR"},
    {id: 4, key: :egp, code: "EGP"},
    {id: 5, key: :kwd, code: "KWD"},
    {id: 6, key: :aed, code: "AED"},
    {id: 7, key: :iqd, code: "IQD"},
    {id: 8, key: :qar, code: "QAR"},
    {id: 9, key: :jod, code: "JOD"},
    {id: 10, key: :lbp, code: "LBP"},
  ]

  class << self
    def find(id, locale = I18n.locale)
      if _d = CURRENCIES.find { |d| d[:id] == id.to_i }
        hash_to_object(_d, locale)
      end
    end

    def find_by_key(key, locale = I18n.locale)
      if _d = CURRENCIES.find { |d| d[:key].to_s == key.to_s }
        hash_to_object(_d, locale)
      end
    end

    def all(locale = I18n.locale)
      CURRENCIES.map do |d|
        hash_to_object(d, locale)
      end
    end

    private

    def hash_to_object(_d, locale)
      new(_d[:id], _d[:key], I18n.t("currencies.#{_d[:key]}", locale: locale), _d[:code])
    end
  end
end
