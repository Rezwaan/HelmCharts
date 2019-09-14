module Customers
  module MobileHelper
    extend self

    # Normalizes a mobile number and calls
    # Phony.format(mobile, format)
    #
    # @param [String] mobile A mobile number
    # @param [Symbol] format The format to format to, defaults to :international
    # @param [String,Symbol] spaces The character to use for spacing, defaults to an empty string
    #
    # @see https://github.com/floere/phony/blob/master/qed/format.md
    def format_to(mobile:, format: :international, spaces: "")
      return nil if mobile.nil? || format.nil?

      # Normalize mobile (e.g. 966501234567), necessary to convert between
      # formats.
      mobile = Phony.normalize(mobile)

      Phony.format(mobile, format: format, spaces: spaces)
    end
  end
end
