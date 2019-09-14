class RejectReasons::RejectReason < Struct.new(:id, :key, :text)
  REJECT_REASONS = [
    {id: 1, key: :driver_unavailable},
    {id: 2, key: :kitchen_busy},
    {id: 3, key: :item_not_available},
  ]

  class << self
    def find(id, locale = I18n.locale)
      if _d = REJECT_REASONS.find { |d| d[:id] == id.to_i }
        hash_to_object(_d, locale)
      end
    end

    def find_by_key(key, locale = I18n.locale)
      if _d = REJECT_REASONS.find { |d| d[:key].to_s == key.to_s }
        hash_to_object(_d, locale)
      end
    end

    def all(locale = I18n.locale)
      REJECT_REASONS.map do |d|
        hash_to_object(d, locale)
      end
    end

    private

    def hash_to_object(_d, locale)
      new(_d[:id], _d[:key], I18n.t("reject_reasons.#{_d[:key]}", locale: locale))
    end
  end
end
