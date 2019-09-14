module Integrations
  module Base
    module Errors
      class FailedToCreateOrderError < ::Errors::ErrorWithData
        def initialize(msg = "FailedToCreateOrder Error", data = {})
          super(msg, data)
        end
      end
    end
  end
end
