module Tickets
  module FieldTypes
    class NumberFieldType
      class << self
        def is_valid?(value:)
          true
        end

        def name
          "number"
        end
      end
    end
  end
end
