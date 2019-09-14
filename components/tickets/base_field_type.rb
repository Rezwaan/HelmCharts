module Tickets
  class BaseFieldType
    class << self
      def is_valid?(ticket:)
        true
      end
    end
  end
end
