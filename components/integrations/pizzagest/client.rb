module Integrations
  module Pizzagest
    class Client
      def initialize(config:)
        @base_url = config[:base_url]
        @client_code = config[:client_code]
        @secret = config[:secret]
        @connection = Faraday.new(url: @base_url) { |faraday|
          faraday.request :url_encoded
          faraday.options[:open_timeout] = 10
          faraday.options[:timeout] = 60
          faraday.response :logger
          faraday.headers["Charset"] = "UTF-8"
          faraday.adapter Faraday.default_adapter
        }
      end

      def get_branches_info(branch_code: nil)
        data = {}
        data["BranchCode"] = branch_code unless branch_code.nil?
        post(function: "getBranchesInfo", data: data)
      end

      def get_menu_info(branch_code:, language: "en")
        get(function: "getMenuInfo", params: {"BranchCode" => branch_code, "Language" => language})
      end

      def add_new_ticket(order:)
        post(function: "addNewTicket", data: order)
      end

      def get_order_status(phone_number:, language: "en")
        get(function: "getOrderStatus", params: {"Phone" => phone_number, "Language" => language})
      end

      def get_products_out_of_stock(branch_code:)
        data = {}
        data["BranchCode"] = branch_code
        post(function: "getProductsOutOfStock", data: data)
      end

      def get_toppings_out_of_stock(branch_code:)
        data = {}
        data["BranchCode"] = branch_code
        post(function: "getToppingsOutOfStock", data: data)
      end

      private

      def get(function:, params: {})
        data = {"ClientCode": @client_code, "Timestamp": Time.now.to_i.to_s}
        data.merge!(params)
        data_str = data.to_json
        hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, data_str + data_str.bytesize.to_s)
        url = "#{@base_url}/#{function}"
        response = @connection.get url, {data: data_str, hash: hmac}
        json = JSON.parse(response.body) unless response.body.blank?
        return json["response"] if json && !json["error"].present?

        error_data = {connection: @connection, response: response}
        error_code = json["error"] && json["error"]["Code"]
        error_message = json["error"] && json["error"]["Error"]
        raise Base::Errors::ApiError.new("API Request Failed:: Code: #{error_code} => #{ErrorCodes::TABLE[error_code]} Message: #{error_message}", error_data)
      rescue Net::ReadTimeout, Faraday::Error => error
        error_data = {connection: @connection, error_code: error.class, error_text: error.message}
        raise Base::Errors::ConnectionError.new(error_data, "Connection Failed")
      end

      def post(function:, data:)
        mandatory_fields = {"ClientCode": @client_code, "Timestamp": Time.now.to_i.to_s}
        data = data.merge(mandatory_fields)
        data_str = JSON.generate(data)
        hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, data_str + data_str.bytesize.to_s)
        url = "#{@base_url}/#{function}"
        response = @connection.post url, {data: data_str, hash: hmac}
        json = JSON.parse(response.body)
        return json["response"] unless json["error"].present?

        error_data = {connection: @connection, response: response}
        error_code = json["error"] && json["error"]["Code"]
        error_message = json["error"] && json["error"]["Error"]

        raise Base::Errors::ApiError.new("API Request Failed:: Code: #{error_code} => #{ErrorCodes::TABLE[error_code]} Message: #{error_message}", error_data)
      rescue Net::ReadTimeout, Faraday::Error => error
        error_data = {connection: @connection, error_code: error.class, error_text: error.message}

        raise Base::Errors::ConnectionError.new(error_data, "Connection Failed")
      end
    end
  end
end
