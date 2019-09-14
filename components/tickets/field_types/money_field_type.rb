module Tickets
  module FieldTypes
    class MoneyFieldType
      class << self
        def is_valid?(value:)
          true
        end

        def name
          "money"
        end
      end
    end
  end
end
