require "uri"

module Integrations
  module Shawarmer
    class Client
      def initialize(config:)
        config = config&.with_indifferent_access

        @api_version = URI(config[:base_url]).path
        @credentials = {
          SystemUsername: config[:username],
          SystemPassword: config[:password],
        }

        configure_faraday_connection(config)
      end

      def authenticate
        result = post(path: "Auth/Authenticate", params: @credentials)

        configure_token_header(result["token"])
      end

      def fetch_menu
        authenticate

        get(path: "Menu/GetSystemUserMenu")
      end

      def fetch_out_of_stock_items(store_id)
        authenticate

        get(path: "Menu/GetStoreUnavailableItems", query: {StoreId: store_id})
      end

      def fetch_store_list(data)
        authenticate

        post(path: "stores/GetStoresList", params: data)
      end

      def validate_order(data)
        authenticate

        post(path: "Orders/ValidateOrder", params: data)
      end

      def place_order(data)
        authenticate

        post(path: "Orders/PlaceOrder", params: data)
      end

      def fetch_order_status(data)
        authenticate

        post(path: "Orders/GetOrderStatus", params: data)
      end

      def fetch_customer_by_phone(phone)
        authenticate

        get(path: "Customer/GetCustomerByPhoneNumber", query: {PhoneNumber: phone})
      end

      def create_customer(data)
        authenticate

        post(path: "Customer/RegisterNewCustomer", params: data)
      end

      def payment_types
        authenticate

        get(path: "User/GetSystemUserAvailablePayTypes")
      end

      private

      def get(path:, query: {})
        response = @connection.get("#{@api_version}/#{path}", query)

        handle_response(response, path, query)
      rescue Net::ReadTimeout, Faraday::Error => error
        raise Base::Errors::ConnectionError.new("Shawarmer Timeout on GET from #{path}", {
          connection: @connection,
          error_code: error.class,
          error_text: error.message,
          path: path,
          query: query,
        })
      end

      def post(path:, params:)
        response = @connection.post("#{@api_version}/#{path}", params.to_json)

        handle_response(response, path, params)
      rescue Net::ReadTimeout, Faraday::Error => error
        raise Base::Errors::ConnectionError.new("Shawarmer Timeout on POST to #{path}", {
          connection: @connection,
          error_code: error.class,
          error_text: error.message,
          path: path,
          params: params,
        })
      end

      def handle_response(response, path, payload)
        raise_error(response, path, payload) if response.status == 400
        raise_auth_error(response, path, payload) if response.status == 401
        raise_service_error(response, path, payload) if response.status == 500

        body = JSON.parse(response.body)
        body["Result"]
      end

      def raise_error(response, path, payload)
        parsed_response = JSON.parse(response.body)
        error_data = error_context(response, path, payload)
        errors = parsed_response.dig("Errors")

        unless errors.present?
          parsed_response.each do |field, errors|
            raise Base::Errors::ApiError.new("API Request Failed:: Field: #{field}, Message: #{errors.join("-")}",
                                             error_data)
          end

          return
        end

        first_error = errors

        if first_error.class.name == "Array"
          first_error = first_error.first
        end

        field = first_error.dig("Field")
        msg = first_error.dig("Error")

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{field}, Message: #{msg}",
                                          error_data)
      end

      def raise_auth_error(response, path, payload)
        error_data = error_context(response, path, payload)
        error_field = "Token"
        message = "You should get a valid token by calling authenticate."

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{error_field}, Message: #{message}",
                                         error_data)
      end

      def raise_service_error(response, path, payload)
        error_data = error_context(response, path, payload)
        error_field = "Service"
        message = "internal server error."

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{error_field}, Message: #{message}",
                                         error_data)
      end

      def error_context(response, path, payload)
        {
          connection: @connection,
          response_body: response&.body || response,
          path: path,
          payload: payload,
        }
      end

      def configure_token_header(token)
        @connection.headers["Authorization"] = "Bearer #{token}"
      end

      def configure_faraday_connection(config)
        @connection = Faraday.new(url: config[:base_url]) { |faraday|
          faraday.options[:open_timeout] = 10
          faraday.options[:timeout] = 60
          faraday.response :logger
          faraday.headers["Charset"] = "UTF-8"
          faraday.headers["Content-Type"] = "application/json"
          faraday.adapter Faraday.default_adapter
        }
      end
    end
  end
end
