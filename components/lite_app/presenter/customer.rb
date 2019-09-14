class LiteApp::Presenter::Customer
  def initialize(dto:)
    @dto = dto
  end

  def present(customer_address: nil)
    {
      id: @dto.id,
      name: @dto.name,
      phone_number: @dto.phone_number,
      address: {
        latitude: customer_address&.latitude,
        longitude: customer_address&.longitude,
      },
    }
  end
end
