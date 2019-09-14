module RushDeliveries
  module Pace
    module Helpers
      class Authenticator
        def initialize
          @secret = Rails.application.secrets.pace_api[:client_secret]
        end

        def authenticate(token:)
          return false unless token.respond_to?(:split)

          parts = token.split(" ")
          return false if parts[0] != "Bearer"

          # Return a truthy value on success
          JWT.decode(parts[1], @secret) || true
        rescue JWT::DecodeError
          false
        end

        def generate_token(time: (Time.now + 2.hours).to_i)
          payload = {
            exp: time,
          }

          JWT.encode(payload, @secret)
        end
      end
    end
  end
end
