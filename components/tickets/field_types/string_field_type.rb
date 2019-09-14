module Tickets
  module FieldTypes
    class StringFieldType
      class << self
        def is_valid?(value:)
          true
        end

        def name
          "string"
        end
      end
    end
  end
end
