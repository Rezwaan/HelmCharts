require "uri"

module Integrations
  module Foodics
    # This client is built to interact with Foodics API V2
    class Client
      def initialize(config:)
        @base_url = URI(config[:base_url]).to_s
        @secret = config[:secret]
        @business_id = config[:business_id]

        configure_faraday_connection
      end

      def authenticate
        result = post(path: "token", params: {secret: @secret})
        token = result.dig("token")

        configure_token_header(token)
      end

      def allowed_businesses
        authenticate
        businesses = get(path: "businesses")

        extract_nested_array_from_parsed_json(
          parsed_json: businesses,
          array_key: "businesses"
        )
      end

      def current_business
        allowed_businesses.find { |business| business["hid"] == @business_id }
      end

      def branches
        authenticate
        branches = get(path: "branches")

        extract_nested_array_from_parsed_json(
          parsed_json: branches,
          array_key: "branches"
        )
      end

      def catalog
        authenticate

        parallel_get_requests(["categories", "products", "modifiers"])
      end

      def order(id)
        authenticate

        get(path: "orders/#{id}")
      end

      def categories
        authenticate

        get(path: "categories")
      end

      def products
        authenticate

        get(path: "products")
      end

      def modifiers
        authenticate

        get(path: "modifiers")
      end

      # https://dash.foodics.com/api-docs#list-inactive-items
      # Returns an object with arrays of HIDs of inactive:
      # - categories
      # - products
      # - modifiers
      # - sizes
      # - tags
      def inactive_items(branch_hid:)
        authenticate

        get(path: "items-activation/inactive/#{branch_hid}")
      end

      def payment_methods
        authenticate
        get(path: "payment_methods")
      end

      def customer_by_phone(phone)
        authenticate
        get(path: "customers", filters: {phone: phone})
      end

      def customer_address(id)
        authenticate

        get(path: "customer-addresses/#{id}")
      end

      def create_customer(data)
        authenticate

        post(path: "customers", params: data)
      end

      def create_customer_address(data)
        authenticate

        post(path: "customer-addresses", params: data)
      end

      def create_order(data)
        authenticate

        post(path: "orders", params: data)
      end

      def taxes
        authenticate
        taxes = get(path: "taxes")

        extract_nested_array_from_parsed_json(
          parsed_json: taxes,
          array_key: "taxes"
        )
      end

      private

      def get(path:, query: {})
        response = @connection.get("#{@base_url}/#{path}", query)

        handle_response(response, path, query)
      rescue Net::ReadTimeout, Faraday::Error => error
        raise Base::Errors::ConnectionError.new("Foodics Timeout on GET from #{path}", {
          url_prefix: @connection&.url_prefix.to_s,
          connection: @connection,
          error_code: error.class,
          error_text: error.message,
          path: path,
          query: query,
        })
      end

      def post(path:, params:)
        response = @connection.post("#{@base_url}/#{path}", params.to_json)

        handle_response(response, path, params)
      rescue Net::ReadTimeout, Faraday::Error => error
        raise Base::Errors::ConnectionError.new("Foodics Timeout on POST to #{path}", {
          url_prefix: @connection&.url_prefix.to_s,
          connection: @connection,
          error_code: error.class,
          error_text: error.message,
          path: path,
          params: params,
        })
      end

      def parallel_get_requests(paths)
        responses = []
        @connection.in_parallel do
          paths.each do |path|
            responses << get(path: path)[path]
          end
        end

        responses
      end

      def handle_response(response, path, payload)
        case response&.status
        when 400 then raise_error(response, path, payload)
        when 401 then raise_auth_error(response, path, payload)
        when 500, 501 then raise_service_error(response, path, payload)
        end

        JSON.parse(response&.body)
      end

      def extract_nested_array_from_parsed_json(parsed_json:, array_key:)
        parsed_json&.fetch(array_key.to_s, []) || []
      end

      def raise_error(response, path, payload)
        parsed_response = JSON.parse(response.body)
        error_data = error_context(response, path, payload)

        if parsed_response["messages"]
          parsed_response["messages"].each do |field, errors|
            raise Base::Errors::ApiError.new("API Request Failed:: Field: #{field}, Message: #{errors.join("-")}", error_data)
          end
        else
          raise Base::Errors::ApiError.new("API Request Failed:: Field: #{field}, Message: #{parsed_response["error"]}", error_data)
        end
      end

      def raise_auth_error(response, path, payload)
        error_data = error_context(response, path, payload)
        error_field = "Token"
        message = "You should get a valid token by calling authenticate."

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{error_field}, Message: #{message}", error_data)
      end

      def raise_service_error(response, path, payload)
        error_data = error_context(response, path, payload)
        error_field = "Service"
        message = "Internal server error."

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{error_field}, Message: #{message}", error_data)
      end

      def error_context(response, path, payload)
        {
          url_prefix: @connection&.url_prefix.to_s,
          connection: @connection,
          response_body: response&.body || response,
          path: path,
          payload: payload,
        }
      end

      def configure_token_header(token)
        @connection.headers["Authorization"] = "Bearer #{token}"
      end

      def configure_faraday_connection
        @connection = Faraday.new(url: @base_url) { |faraday|
          faraday.options[:open_timeout] = 10
          faraday.options[:timeout] = 60
          faraday.response :logger
          faraday.headers["Charset"] = "UTF-8"
          faraday.headers["Accept"] = "application/json"
          faraday.headers["Content-Type"] = "application/json"
          faraday.headers["X-business"] = @business_id
          faraday.adapter Faraday.default_adapter
        }
      end
    end
  end
end
