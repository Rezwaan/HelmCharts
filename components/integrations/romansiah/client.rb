require "uri"

module Integrations
  module Romansiah
    class Client
      attr_reader :connection, :response, :result, :api_version, :credentials

      def initialize(config:)
        set_api_version(config)
        set_credentials(config)
        set_faraday_connection(config)
      end

      def branches
        @result = get(path: "Common/GetBranches")["data"]
      end

      def authenticate
        set_lang("1")
        @result = post(path: "GetAccessToken", params: credentials)
        set_token
      end

      def get_catalog
        @result = get(path: "Categories/GetCategories")["data"]
      end

      def get_order_status(id)
        @result = get(path: "Orders/GetOrderStatusById/#{id}")
      end

      def get_customer_by_phone(phone)
        authenticate
        @result = get(path: "Customers/GetCustomerByPhone", query: {phone: phone})["data"]
      end

      def create_order(data)
        set_lang("1")
        authenticate
        @result = post(path: "Orders/CreateCustomOrder", params: data)
      end

      def get_order_status_by_id(id)
        authenticate
        @result = get(path: "Orders/GetOrderStatusById/#{id}")["data"]
      end

      def create_customer(data)
        set_lang("1")
        @result = post(path: "Customers/CreateCustomer", params: data)
      end

      def create_address(data)
        @result = post(path: "Common/AddAddress", params: data)
      end

      def get_products(query)
        @result = get(path: "Products/GetProducts", query: query)["data"]
      end

      def set_lang(lang)
        connection.headers["Lang"] = lang
      end

      private

      def get(path:, query: nil)
        @response = connection.get "#{api_version}/#{path}" unless query
        @response = connection.get "#{api_version}/#{path}", query if query
        handle_response
      end

      def post(path:, params:)
        version = path == "GetAccessToken" ? "api" : api_version
        @response = connection.post "#{version}/#{path}", params.to_json
        handle_response
      rescue Net::ReadTimeout, Faraday::Error => error
        puts error
        puts error.class.name
        error_data = {connection: @connection, error_code: error.class, error_text: error.message}
        raise Base::Errors::ConnectionError.new(error_data, "Connection Failed")
      end

      def handle_response
        raise_error if response.status == 400
        raise_auth_error if response.status == 401
        raise_service_error if response.status == 500 || response.status == 503

        body = JSON.parse(response.body)
        raise_error if body["status"] == false

        body
      end

      def raise_error
        errors = JSON.parse(response.body)["errors"]
        error_data = {connection: connection, response: response}
        raise Base::Errors::ApiError.new("API Request Failed:: Field: N/A, Message: #{errors.join(", ")}", error_data)
      end

      def raise_auth_error
        error_data = {connection: connection, response: response}
        error_field = "Token"
        message = "You should get a valid token by calling authenticate."

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{error_field}, Message: #{message}", error_data)
      end

      def raise_service_error
        error_data = {connection: connection, response: response}
        error_field = "Service"
        message = "internal server error."

        raise Base::Errors::ApiError.new("API Request Failed:: Field: #{error_field}, Message: #{message}", error_data)
      end

      def set_credentials(config)
        @credentials = {
          phone: config[:phone],
          password: config[:password],
        }
      end

      def set_api_version(config)
        @api_version = URI(config[:base_url]).path
      end

      def set_token
        connection.headers["Authorization"] = "Basic #{result["token"]}"
      end

      def set_faraday_connection(config)
        @uri = URI(config[:base_url])
        @connection = Faraday.new(url: "#{@uri.scheme}://#{@uri.host}:#{@uri.port}") { |faraday|
          faraday.options[:open_timeout] = 10
          faraday.options[:timeout] = 60
          faraday.response :logger
          faraday.headers["Charset"] = "UTF-8"
          faraday.headers["Accept"] = "application/json"
          faraday.headers["Content-Type"] = "application/json"
          faraday.headers["RequestSource"] = "50"
          faraday.adapter Faraday.default_adapter
        }
      end
    end
  end
end
