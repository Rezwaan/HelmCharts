module Integrations
  module Shawarmer
    class OrderStatus
      STATUSES = [
        {id: 1, shawarmer: "New Order", dome: :accepted_by_store},
        {id: 2, shawarmer: "Initial", dome: :accepted_by_store},
        {id: 3, shawarmer: "Open", dome: :accepted_by_store},
        {id: 4, shawarmer: "In Kitchen", dome: :accepted_by_store},
        {id: 5, shawarmer: "Ready", dome: :out_for_delivery},
        {id: 6, shawarmer: "Canceled", dome: :cancelled_by_store},
        {id: 7, shawarmer: "Closed", dome: :out_for_delivery},
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
