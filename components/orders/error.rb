module Orders
  class Error < StandardError
    attr_accessor :message, :error_data
    def initialize(message:, error_data: {})
      @message = message
      @error_data = error_data
      super
    end

    class StatusChangedNotAllowed < Error
      def initialize(message:, error_data: {})
        super(message: message, error_data: error_data)
      end
    end
  end
end
