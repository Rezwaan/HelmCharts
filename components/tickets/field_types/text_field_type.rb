module Tickets
  module FieldTypes
    class TextFieldType
      class << self
        def is_valid?(value:)
          true
        end

        def name
          "text"
        end
      end
    end
  end
end
