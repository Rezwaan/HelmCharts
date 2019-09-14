module Integrations
  module Base
    module Errors
      class ConnectionError < ::Errors::ErrorWithData
        def initialize(msg = "Integration Connection Error", data = {})
          super(msg, data)
        end
      end
    end
  end
end
