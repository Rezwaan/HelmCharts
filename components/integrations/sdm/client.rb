module Integrations
  module Sdm
    class Client
      def initialize(config:)
        @wsdl_url = config[:wsdl_url]
        @license_code = config[:license_code]
        @connection = Savon::Client.new(
          wsdl: @wsdl_url,
          env_namespace: :soapenv,
          log: true,
          open_timeout: 10,
          read_timeout: 120,
          pretty_print_xml: true,
          adapter: :net_http,
          namespaces: {
            "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
            "xmlns:tns" => "http://tempuri.org/",
            "xmlns:sdm" => "http://schemas.datacontract.org/2004/07/SDM_SDK",
            "xmlns:arr" => "http://schemas.microsoft.com/2003/10/Serialization/Arrays",
            "xmlns:i" => "http://www.w3.org/2001/XMLSchema-instance",
            "xmlns:psor" => "PSOrderingDOM.Classes",
          }
        )
      end

      def system_time
        request(:get_system_time)
      end

      def get_menu_templates_list(concept_id:)
        res = request(:get_menu_templates_list, data: {'tns:conceptID': concept_id})

        dig_as_array(res, :cc_menu_template)
      end

      def get_menu_template(concept_id:, menu_template_id:)
        request(:get_menu_template, data: {'tns:conceptID': concept_id, 'tns:menuTemplateID': menu_template_id})
      end

      def get_submenus_list(concept_id:, menu_template_id:, menu_id:)
        res = request(:get_submenus_list, data: {
          'tns:conceptID': concept_id,
          'tns:menuTemplateID': menu_template_id,
          'tns:menuID': menu_id,
        })
        dig_as_array(res, :c_submenu)
      end

      def get_items_list(concept_id:, menu_template_id:, submenu_id:)
        res = request(:get_items_list, data: {
          'tns:conceptID': concept_id,
          'tns:menuTemplateID': menu_template_id,
          'tns:submenuID': submenu_id,
        })

        dig_as_array(res, :c_item)
      end

      def get_modgroups_list(concept_id:, menu_template_id:, item_id:)
        res = request(:get_modgroups_list, data: {
          'tns:conceptID': concept_id,
          'tns:menuTemplateID': menu_template_id,
          'tns:itemID': item_id,
        })
        dig_as_array(res, :c_mod_group)
      end

      def get_modifiers_list(concept_id:, menu_template_id:, modgroup_id:)
        res = request(:get_modifiers_list, data: {
          'tns:conceptID': concept_id,
          'tns:menuTemplateID': menu_template_id,
          'tns:modgroupID': modgroup_id,
        })
        dig_as_array(res, :c_item)
      end

      def get_stores_list(concept_id:)
        res = request(:get_stores_list, data: {
          'tns:conceptID': concept_id,
        })
        res.dig(:cc_store)
      end

      def get_customer_by_mobile(concept_id:, mobile:)
        request(:get_customer_by_mobile, data: {
          'tns:mobileNo': mobile,

          # Order matters here, concept ID has to be last
          'tns:conceptID': concept_id,
        })
      end

      def get_customer_by_id(concept_id:, id:)
        request(:get_customer_by_id, data: {
          'tns:customerID': id,

          # Order matters here, concept ID has to be last
          'tns:conceptID': concept_id,
        })
      end

      # Calls SDM's `GetStoresAreaList`, finds the area ID for that store then
      # calls `get_area` and returns the response of that call
      def get_store_area(concept_id:, store_id:)
        res = request(:get_stores_area_list, data: {
          'tns:conceptID': concept_id,
        })

        store_areas = res&.dig(:cc_store_area)
        return nil if store_areas.nil?

        area_id = nil

        # We get store IDs back from SDM as strings, so use a string for
        # comparison.
        store_id = store_id.to_s

        store_areas.each do |store_area|
          if store_area[:str_id] == store_id
            area_id = store_area[:str_areaid]
          end
        end

        return nil if area_id.nil?

        get_area(area_id: area_id)
      end

      def get_area(area_id:)
        request(:get_area, data: {'tns:areaID': area_id})
      end

      def get_order_details(order_id:)
        request(:get_order_details, data: {'tns:orderID': order_id})
      end

      # @param [String] concept_id The concept ID to create
      # @param [CustomerDTO] customer_dto The customer to create
      # @param [String] mobile a Saudi mobile number in national format (e.g. 0501234567)
      #
      # @todo Make this method handle all mobiles in a generic way, we tried to
      #       use Phony (generic phone library) but the SDM requirements don't
      #       seem to be a part of international phone standards. This method
      #       assumes it's receiving a Saudi mobile in national format.
      def create_customer(concept_id:, customer_dto:, mobile:)
        # Share the minimum amount of information possible, value customer
        # privacy.

        # Max length for names is 50 on SDM, and our customers might not have
        # names but SDM requires them, so we'll make one up in this case.
        truncated_name = if customer_dto.name
          customer_dto.name[0...50]
        else
          "No face"
        end

        # Create an email with some randomness in case we need to re-create the
        # customer later (so we don't hit a 'username already exists' error)
        random_chars = SecureRandom.hex[0..5]
        email = "#{mobile}-#{random_chars}@#{username_domain}"

        # Don't try to register the customer address here in one step, we tried.
        # For some reason they won't save it on their side.
        request(:register_customer, data: {
          'tns:customer': {
            "sdm:CUST_CLASSID" => -1,
            "sdm:CUST_CORPID" => "",
            "sdm:EMAIL" => email,
            "sdm:CUST_FIRSTNAME" => truncated_name,
            "sdm:CUST_GENDER" => "None",
            "sdm:CUST_LASTNAME" => truncated_name,
            "sdm:CUST_MARITALSTATUS" => "None",
            "sdm:CUST_NATID" => -1,
            "sdm:CUST_PHONEAREACODE" => mobile[1, 2], # e.g. 50
            "sdm:CUST_PHONELOOKUP" => mobile[1..], # e.g. 501234567
            "sdm:CUST_PHONENUMBER" => mobile[3..], # e.g. 1234567
            "sdm:CUST_PHONETYPE" => 2, # Mobile
            "sdm:CUST_TITLE" => 1,
            "sdm:PASSWORD" => SecureRandom.hex,
            "sdm:USERNAME" => email,
            "sdm:WCUST_CORPID" => "",
            "sdm:WCUST_FIRSTNAME" => truncated_name,
            "sdm:WCUST_ISGUEST" => false,
            "sdm:WCUST_LASTNAME" => truncated_name,
            "sdm:WCUST_STATUS" => 4, # Verified
          },
        })
      end

      # @param [String] customer_id The customer ID to add an address to
      # @param [Hash] address The address to add, genereated by SdmAddress#to_sdm_customer_address
      # @param [String] mobile a Saudi mobile number in national format (e.g. 0501234567)
      #
      # @todo Make this method work with mobiles of all supported countries.
      def register_customer_address(customer_id:, address:, mobile:)
        # Add phone number to address
        address = address.merge({
          "sdm:ADDR_PHONEAREACODE" => mobile[1, 2], # e.g. 50
          "sdm:ADDR_PHONELOOKUP" => mobile[1..], # e.g. 501234567
          "sdm:ADDR_PHONENUMBER" => mobile[3..], # e.g. 1234567
          "sdm:ADDR_PHONETYPE" => 2,
        })

        # Make sure the address is sorted alphabetically by its keys (SDM
        # requires this.)
        address = address.sort_by { |k, v| k.to_s }.to_h

        request(:register_address_by_id, data: {
          :'tns:customerRegistrationID' => customer_id,
          "tns:address" => address,
        })
      end

      # @param [Hash] sdm_order An order serialized to SDM's format by the Serializers::DomeToSdm::OrderSerializer
      def create_order(sdm_order:)
        res = request(:update_order, data: sdm_order)

        # We should get the order ID back in the response, and it should always
        # be larger than 0 if the order went through
        return res if res.respond_to?(:to_i) && res.to_i > 0

        backend_order_id_notes = sdm_order.dig("tns:orderNotes1")

        raise Sdm::Errors::FailedToCreateOrderError.new(
          "Failed to create order with backend ID on SDM #{backend_order_id_notes}",
          {
            request_body: sdm_order,
            response: res,
          }
        )
      end

      private

      def request(function, data: {})
        mandatary_data = {"tns:licenseCode" => @license_code}
        message = mandatary_data.merge(data)
        response = @connection.call(function, message: message)
        response.http.body = response.http.body.gsub("&#x0;", "")
        response_body = response.body
        result_code = response_body[(function.to_s + "_response").to_sym][:sdk_result][:result_code]

        if result_code == "Success"
          return response_body[(function.to_s + "_response").to_sym][(function.to_s + "_result").to_sym]
        elsif result_code.in?(Integrations::Sdm::ResultCodes::EMPTY_LISTS)
          return []
        elsif result_code.in?(Integrations::Sdm::ResultCodes::NONEXISTENT_RECORDS)
          return nil
        elsif result_code == Integrations::Sdm::ResultCodes::STORE_OUT_OF_WORKING_HOURS
          raise Sdm::Errors::OutOfWorkingHoursError
        elsif result_code.nil?
          raise Base::Errors::ApiError.new(
            "No result code in #{function} call",
            data: {
              response: response_body,
              request: message,
            }
          )
        else
          raise Base::Errors::ApiError.new(
            "Unknown result code in #{function} call",
            data: {
              response: response_body,
              request: message,
            }
          )
        end
      rescue Savon::InvalidResponseError => error
        raise Base::Errors::ApiError.new(
          "Invalid Soap Response in #{function} call. #{error.message}",
          data: {
            request_body: data,
            response_body: response_body,
          }
        )
      rescue Errno::ECONNREFUSED, Errno::EINVAL, Errno::ECONNRESET, EOFError, SocketError,
             Timeout::Error, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
             Net::HTTPClientError, Net::HTTPServerError, Savon::Error => error

        raise Base::Errors::ConnectionError.new("Connection Error in #{function} call. #{error.message}", {
          request_body: data,
          response_body: response_body,
        })
      end

      def dig_as_array(object, property)
        return object if object.is_a?(Array)

        ensure_is_array(object.dig(property))
      end

      def ensure_is_array(thing)
        return thing if thing.is_a?(Array)

        return [] if thing.nil?

        [thing]
      end

      # The domain to use when registering users in SDM
      def username_domain
        Rails.env.production? ? "posdome.com" : "posdome.dev"
      end
    end
  end
end
