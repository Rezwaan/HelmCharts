module Integrations
  module Foodics
    # 1 => Pending
    # 2 => Active
    # 3 => Void
    # 4 => Done
    class OrderStatus
      STATUSES = [
        {id: 1, foodics: 1, dome: :received_successfully},
        {id: 2, foodics: 2, dome: :accepted_by_store},
        {id: 3, foodics: 3, dome: :cancelled_by_store},
        {id: 4, foodics: 4, dome: :out_for_delivery},
      ]

      class << self
        def failed?(status)
          st = mapped_status(status)
          [:cancelled_by_store].include? st
        end

        def mapped_status(status)
          st = STATUSES.find { |st| st[:foodics] == status }
          return st[:dome] if st
          nil
        end
      end
    end
  end
end
