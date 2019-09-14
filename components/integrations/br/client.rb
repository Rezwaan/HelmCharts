require "uri"

module Integrations
  module Br
    class Client
      def initialize(config:)
        @uri = URI(config[:wsdl_url])

        @connection = Faraday.new(url: "#{@uri.scheme}://#{@uri.host}:#{@uri.port}") { |faraday|
          faraday.options[:open_timeout] = 10
          faraday.options[:timeout] = 60
          faraday.response :logger
          faraday.headers["Content-Type"] = "text/xml;charset=UTF-8"
          faraday.adapter Faraday.default_adapter
        }
      end

      def register_order(data:)
        request("HDUE_REGISTERORDER", data: data)
      end

      def order_status(data:)
        request("HDUE_ORDERSTATUS", data: data)
      end

      def get_stores
        request("HDUE_STORE")
      end

      def get_catalog
        functions = ["HDUE_CATEGORY", "HDUE_FLAVOUR", "HDUE_PRODUCT", "HDUE_TOPPINGS"].freeze

        parallel_requests(
          functions,
          data: Array.new(functions.length, nil)
        )
      end

      private

      def request(function, data: nil)
        @connection.headers["SOAPAction"] = function

        response = if data.nil?
          @connection.post "#{@uri.path}?#{@uri.query}"
        else
          @connection.post "#{@uri.path}?#{@uri.query}", data.to_xml
        end
        processed_response = process_response(response)

        Nokogiri.XML(processed_response.body)
      rescue Net::ReadTimeout, Faraday::Error => error
        error_data = {connection: @connection, error_code: error.class, error_text: error.message}
        raise Base::Errors::ConnectionError.new(error_data, "Connection Failed")
      end

      def parallel_requests(functions, data: [])
        responses = []
        @connection.in_parallel do
          functions.each_with_index do |function, index|
            responses << request(function, data: data[index])
          end
        end

        responses
      end

      private

      def process_response(response)
        if /soapenv:Fault/.match?(response.body)
          handle_error(response)
        else
          response
        end
      end

      def handle_error(response)
        xml = Nokogiri::XML(response.body)
        xpath = "/soapenv:Envelope/soapenv:Body/soapenv:Fault//faultstring"
        msg = xml.xpath(xpath).text

        raise Base::Errors::SoapError.new("Error from server: #{msg}", response)
      end
    end
  end
end
