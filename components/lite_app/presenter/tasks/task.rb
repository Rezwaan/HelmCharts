class LiteApp::Presenter::Tasks::Task
  def initialize(dto:)
    @dto = dto
  end

  def present
    {
      id: @dto.id,
    }
  end
end
