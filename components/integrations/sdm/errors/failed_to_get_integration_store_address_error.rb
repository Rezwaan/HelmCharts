module Integrations
  module Sdm
    module Errors
      class FailedToGetIntegrationStoreAddressError < ::Errors::ErrorWithData
        def initialize(msg = "Failed to get integration store address error", data = {})
          super(msg, data)
        end
      end
    end
  end
end
