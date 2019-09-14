module Integrations
  module Br
    class OrderStatus
      STATUSES = [
        {id: 1, br: "S", dome: :accepted_by_store},
        {id: 2, br: "A", dome: :accepted_by_store},
        {id: 3, br: "C", dome: :cancelled_by_store},
      ]

      class << self
        def failed?(status)
          st = mapped_status(status)
          [:cancelled_by_store].include? st
        end

        def mapped_status(status)
          st = STATUSES.find { |st| st[:br] == status }
          return st[:dome] if st
          nil
        end
      end
    end
  end
end
