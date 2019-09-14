module Integrations
  module Base
    module Errors
      class ApiError < ::Errors::ErrorWithData
        def initialize(msg = "Integration API Error", data = {})
          super(msg, data)
        end
      end
    end
  end
end
