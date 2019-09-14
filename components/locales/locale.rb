class Locales::Locale < Struct.new(:id, :name, :key, :rtl)
  LOCALES = [
    {id: 1, name: "English", key: :en, default: true, rtl: false},
    {id: 2, name: "Arabic", key: :ar, default: false, rtl: true},
    {id: 3, name: "Urdu", key: :ur, default: false, rtl: true},
  ]

  def name
    _d = LOCALES.find { |d| d[:id] == id }
    _d[:name]
  end

  class << self
    def find(id)
      if _d = LOCALES.find { |d| d[:id] == id.to_i }
        hash_to_object(_d)
      end
    end

    def find_by_key(key)
      if _d = LOCALES.find { |d| d[:key].to_s =~ /\A#{key.to_s}\z/i }
        hash_to_object(_d)
      end
    end

    def all
      LOCALES.map do |d|
        hash_to_object(d)
      end
    end

    def ids_as_str
      LOCALES.map { |d| d[:id].to_s }
    end

    def default
      if _d = LOCALES.find { |d| d[:default] }
        hash_to_object(_d)
      end
    end

    def default_locale
      _d = LOCALES.find { |d| d[:default] } || LOCALES.first
      _d ? _d[:key] : nil
    end

    private

    def hash_to_object(_d)
      new(_d[:id], _d[:name], _d[:key], _d[:rtl])
    end
  end
end
