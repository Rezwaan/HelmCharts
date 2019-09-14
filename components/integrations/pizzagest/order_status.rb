module Integrations
  module Pizzagest
    class OrderStatus
      STATUSES = [
        {id: 1, pizzagest: "Placed", dome: :accepted_by_store},
        {id: 2, pizzagest: "Preparation", dome: :accepted_by_store},
        {id: 3, pizzagest: "Backing", dome: :accepted_by_store},
        {id: 4, pizzagest: "Packing", dome: :accepted_by_store},
        {id: 5, pizzagest: "Delivering", dome: :out_for_delivery},
        {id: 6, pizzagest: "Terminated", dome: :cancelled_by_store},
        {id: 6, pizzagest: "Canceled", dome: :cancelled_by_store},
        {id: 7, pizzagest: "Confirming", dome: :accepted_by_store},
        {id: 8, pizzagest: "DriverArrived", dome: :out_for_delivery},
        {id: 9, pizzagest: "Error", dome: :cancelled_by_store},
      ]

      class << self
        def failed?(status)
          st = mapped_status(status)
          [:cancelled_by_store].include? st
        end

        def mapped_status(status)
          st = STATUSES.find { |st| st[:pizzagest] == status }
          return st[:dome] if st
          nil
        end
      end
    end
  end
end
