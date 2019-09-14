module Integrations
  module Sdm
    module Errors
      class FailedToCreateOrderError < ::Errors::ErrorWithData
        def initialize(msg = "Failed to Create Order Error", data = {})
          super(msg, data)
        end
      end
    end
  end
end
