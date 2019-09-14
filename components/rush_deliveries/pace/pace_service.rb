module RushDeliveries
  module Pace
    class PaceService
      def initialize
        @url = Rails.application.secrets.pace_api[:url]
        @client_id = Rails.application.secrets.pace_api[:client_id]

        @connection = Faraday.new(url: @url) { |faraday|
          faraday.headers["Content-Type"] = "application/json"
          faraday.headers["Authorization"] = token
          faraday.adapter Faraday.default_adapter
          faraday.use Faraday::Response::RaiseError
        }
      end

      def submit_order(order:)
        post(endpoint: "​platforms/orders", body: order)
      end

      private

      def token
        token = RushDeliveries::Pace::Helpers::Authenticator.new.generate_token

        "Bearer #{token}"
      end

      def post(endpoint:, body: {})
        response = @connection.post(endpoint, body) { |req|
          req.params["client_id"] = @client_id
          req.body = body.to_json
        }

        JSON.parse(response.body)
      end
    end
  end
end
