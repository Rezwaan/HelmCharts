module Integrations
  module Base
    module Errors
      class TemporaryUnavailableError < StandardError
        attr_reader :last_response

        def initialize(message, last_response)
          @last_response = last_response
          super(message)
        end
      end
    end
  end
end
