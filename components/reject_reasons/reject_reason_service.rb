module RejectReasons
  class RejectReasonService
    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc", light: false)
      RejectReasons::RejectReason.all.map { |reject_reason| create_dto(reject_reason) }
    end

    def fetch(id:, locale: I18n.locale)
      reject_reason = RejectReasons::RejectReason.find(id, locale)
      return nil unless reject_reason
      create_dto(reject_reason)
    end

    def fetch_by_key(key:, locale: I18n.locale)
      reject_reason = RejectReasons::RejectReason.find_by_key(key, locale)
      return nil unless reject_reason
      create_dto(reject_reason)
    end

    private

    def create_dto(reject_reason)
      return nil unless reject_reason
      RejectReasons::RejectReasonDTO.new(
        id: reject_reason.id,
        key: reject_reason.key,
        text: reject_reason.text
      )
    end
  end
end
