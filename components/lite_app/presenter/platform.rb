class LiteApp::Presenter::Platform
  def initialize(dto:)
    @dto = dto
  end

  def present
    {
      id: @dto.id,
      name: @dto.name,
      logo_url: @dto.logo_url,
    }
  end
end
