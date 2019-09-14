module Integrations
  module Romansiah
    class OrderStatus
      STATUSES = [
        {id: 1, shawarmer: "Pending", dome: :accepted_by_store},
        {id: 2, shawarmer: "Processing", dome: :accepted_by_store},
        {id: 3, shawarmer: "Complete", dome: :out_for_delivery},
        {id: 4, shawarmer: "Cancelled", dome: :cancelled_by_store},
        {id: 5, shawarmer: "Kitchen", dome: :accepted_by_store},
        {id: 6, shawarmer: "Driver", dome: :out_for_delivery},
      ]

      class << self
        def failed?(status)
          st = mapped_status(status)
          [:cancelled_by_store].include? st
        end

        def mapped_status(status)
          st = STATUSES.find { |st| st[:shawarmer] == status }
          return st[:dome] if st
          nil
        end
      end
    end
  end
end
