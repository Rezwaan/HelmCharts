# Not an active record model, but created to model SDM address structure
# The sole purpose of this class is to take the response received from calling
# SDM's `GetAreaID`, turn it into an easy to use class, and make that class
# return XML suited for being used when registering a customer address.
#
# Technically what we are doing is using this class to get a store's address
# for the purpose of registering it as a customer's address.
class Integrations::Sdm::Models::SdmAddress
  attr_reader :city_id, :country_id, :district_id, :street_id, :area_id, :province_id

  # @param [Hash] hash The hash is the one returned from SDM's `GetAreaID`, called through our client.
  # @param [String, nil] mobile a Saudi mobile number in national format (e.g. 0501234567), mobile is only necessary for registering a customer address. Defaults to nil
  def initialize(hash:, mobile: nil)
    @city_id = hash&.dig(:area_cityid)&.to_s || "-1"
    @country_id = hash&.dig(:area_countryid)&.to_s || "-1"
    @district_id = hash&.dig(:area_def_districtid)&.to_s || "-1"
    @street_id = hash&.dig(:area_def_streetid)&.to_s || "-1"
    @province_id = hash&.dig(:area_provinceid)&.to_s || "-1"
    @area_id = hash&.dig(:area_id)&.to_s || "-1"
    @mobile = mobile
  end

  def to_sdm_customer_cc_address(
    concept_id:,
    latitude:,
    longitude:,
    customer_id: nil
  )
    {
      "sdm:CC_ADDRESS" =>
        to_sdm_customer_address(
          concept_id: concept_id,
          latitude: latitude,
          longitude: longitude,
          customer_id: customer_id
        ),
    }
  end

  def to_sdm_customer_address(
    concept_id:,
    latitude:,
    longitude:,
    customer_id: nil
  )
    address = {
      "sdm:ADDR_AREAID" => @area_id,
      "sdm:ADDR_CITYID" => @city_id,
      "sdm:ADDR_COUNTRYID" => @country_id,
      "sdm:ADDR_DISTRICTID" => @district_id,
      "sdm:ADDR_MAPCODE" => {
        "sdm:X" => latitude.to_s,
        "sdm:Y" => longitude.to_s,
      },
      "sdm:ADDR_PROVINCEID" => @province_id,
      "sdm:ADDR_STREETID" => @street_id,
      "sdm:WADDR_BUILD_TYPE" => -1,
      "sdm:WADDR_CONCEPTID" => concept_id,
      "sdm:WADDR_TYPE" => -1,
    }

    address["sdm:ADDR_CUSTID"] = customer_id if customer_id

    if @mobile
      address["sdm:ADDR_PHONEAREACODE"] = @mobile[1, 2] # e.g. 50
      address["sdm:ADDR_PHONELOOKUP"] = @mobile[1..] # e.g. 501234567
      address["sdm:ADDR_PHONENUMBER"] = @mobile[3..] # e.g. 1234567
      address["sdm:ADDR_PHONETYPE"] = 2 # Mobile
    end

    # SDM needs alphabetically sorted keys
    address.sort_by { |k, v| k }.to_h
  end
end
