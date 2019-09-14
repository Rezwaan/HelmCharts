class Integrations::Sdm::Models::SdmCustomer
  attr_reader :id, :address_id

  # This hash should be the response as returned from a call to
  # SdmClient#get_customer
  def initialize(hash)
    return if hash.nil?
    raise TypeError, "hash is not an instance of Hash" unless hash.is_a?(Hash)

    @parsed_from_address_hash = false

    if hash[:addr_id]
      @parsed_from_address_hash = true
      dig_from_address_hash(hash)
    else
      dig_from_customer_hash(hash)
    end
  end

  # SDM previously let us create customers without names (we sent them but they
  # weren't saving them) because you must send them a very specific
  # ordered set of undocumented required fields, or else they'll create the
  # customer but not save the name. Customers without names cannot make orders,
  # so we have to fix this ourselves.
  def should_be_recreated?
    # Address hash won't contain the first or last names, we can't determine if
    # the customer needs to be created if we parsed from the address_hash
    return false if @parsed_from_address_hash

    @first_name.nil? || @last_name.nil?
  end

  def is_not_registered?
    @id.nil?
  end

  def has_no_address?
    @address_id.nil?
  end

  private

  # This is used for hashes coming from SDM's GetCustomerByMobile as well as
  # RegisterCustomer
  def dig_from_customer_hash(hash)
    # Get the address (if it's a hash, then it's the only address,
    # and that's what we're looking for)
    address_hash = hash.dig(:addresses, :cc_address)

    # Get the first element if it's an array
    address_hash = address_hash.dig(0) if address_hash.is_a?(Array)

    @address_id = address_hash&.dig(:addr_id)
    @id = hash.dig(:cust_id)
    @first_name = hash.dig(:cust_firstname)
    @last_name = hash.dig(:cust_lastname)
  end

  # This is only used for when we handle a resposne from SDM's
  # RegisterAddressById
  def dig_from_address_hash(hash)
    @address_id = hash.dig(:addr_id)
    @id = hash.dig(:addr_custid)
  end
end
