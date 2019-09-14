class Customers::CustomerService
  def find_or_create(platform_id:, attributes:)
    attributes = attributes.with_indifferent_access if attributes.is_a?(Hash)
    begin
      customer = Customers::Customer.where(platform_id: platform_id, backend_id: attributes[:id]).first_or_initialize
      customer.name = attributes[:name] if attributes[:name].present?
      customer.phone_number = "+#{attributes[:phone][:country_code]}#{attributes[:phone][:number]}" if attributes.dig(:phone, :country_code).present? && attributes.dig(:phone, :number).present?
      return create_dto(customer) if customer.save
      customer.errors
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def find_or_create_address(customer_id:, attributes:)
    customer_address = Customers::CustomerAddress.where(customer_id: customer_id, backend_id: attributes[:id]).first_or_initialize
    customer_address.latitude = attributes[:latitude] if attributes[:latitude].present?
    customer_address.longitude = attributes[:longitude] if attributes[:longitude].present?
    return create_address_dto(customer_address) if customer_address.save
    customer_address.errors
  end

  def fetch(id:)
    customer = Customers::Customer.find_by(id: id)
    create_dto(customer)
  end

  def fetch_address(address_id:)
    customer_address = Customers::CustomerAddress.find_by(id: address_id)
    create_address_dto(customer_address)
  end

  private

  def create_dto(customer)
    return unless customer
    Customers::CustomerDTO.new(
      id: customer.id,
      name: customer.name,
      phone_number: customer.phone_number,
      backend_id: customer.backend_id
    )
  end

  def create_address_dto(customer_address)
    return unless customer_address
    Customers::CustomerAddressDTO.new(
      id: customer_address.id,
      latitude: customer_address.latitude,
      longitude: customer_address.longitude,
      backend_id: customer_address.backend_id
    )
  end
end
