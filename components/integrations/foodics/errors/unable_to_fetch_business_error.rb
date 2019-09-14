module Integrations
  module Foodics
    module Errors
      class UnableToFetchBusinessError < ::Errors::ErrorWithData
        def initialize(msg = "Foodics - Unable to fetch business", data = {})
          super(msg, data)
        end
      end
    end
  end
end
