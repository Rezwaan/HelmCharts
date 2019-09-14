module Integrations
  module Sdm
    module Models
      module Hacks
        extend self

        # This method is meant to be used for SDM stores that do not have an address
        #
        # @param [String] name The name of the integration host, used to determine which default address to return
        # @param [String] mobile A Saudi mobile number in national format (e.g. 0501234567), mobile is necessary for registering a customer address.
        def default_integration_store_address(name:, mobile:)
          kudu_default_address(mobile: mobile) if name.include?("Kudu")

          nil
        end

        def kudu_default_address(mobile:)
          Integrations::Sdm::Models::SdmAddress.new({
            hash: {
              area_cityid: "1",
              area_countryid: "-1",
              area_def_districtid: "2213",
              area_def_streetid: "3087",
              area_provinceid: "1",
              area_id: "607",
            },
            mobile: mobile,
          })
        end
      end
    end
  end
end
