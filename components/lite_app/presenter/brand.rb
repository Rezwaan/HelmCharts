class LiteApp::Presenter::Brand
  def initialize(dto:)
    @dto = dto
  end

  def present
    {
      id: @dto.id,
      name: @dto.name,
      logo_url: @dto.logo_url,
      cover_photo_url: @dto.cover_photo_url,
    }
  end
end
