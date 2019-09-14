module Integrations
  module Foodics
    module Helpers
      module Branch
        extend self

        # @return [true, false] Returns false if all deliverable types are disabled for this branch, and true otherwise.
        def branch_accepts_delivery?(branch_disabled_order_types:)
          if branch_disabled_order_types.nil? ||
              branch_disabled_order_types.length == 0
            return true
          end

          deliverable_order_types = OrderType.deliverable_order_types

          disabled_deliverable_order_types = []

          deliverable_order_types.each do |deliverable_type|
            if branch_disabled_order_types.include?(deliverable_type)
              disabled_deliverable_order_types << deliverable_type
            end
          end

          disabled_deliverable_order_types.length == branch_disabled_order_types.length
        end
      end
    end
  end
end
