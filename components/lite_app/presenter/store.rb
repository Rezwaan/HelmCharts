class LiteApp::Presenter::Store
  def initialize(dto:)
    @dto = dto
  end

  def present
    {
      id: @dto.id,
      name: @dto.name,
      name_en: @dto.name_en,
      name_ar: @dto.name_ar,
      latitude: @dto.latitude,
      longitude: @dto.longitude,
      backend_id: @dto.backend_id,
      brand_id: @dto.brand_id,
      brand: LiteApp::Presenter::Brand.new(dto: @dto.brand).present,
      status: {
        status: @dto.status[:status],
        reopen_at: @dto.status[:reopen_at].to_i,
        last_connected_at: @dto.status[:last_connected_at],
        connectivity_status: @dto.status[:connectivity_status],
      },
    }
  end
end
