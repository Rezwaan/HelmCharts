module Errors
  class ErrorWithData < StandardError
    attr_reader :data

    def initialize(msg = "ErrorWithData", data = {})
      @data = data
      super(msg)
    end

    def raven_context
      {
        extra: {
          data: @data,
        },
      }
    end
  end
end
