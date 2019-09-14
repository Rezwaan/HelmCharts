class Admin::Presenters::Tags::Show
  def initialize(tag)
    @tag = tag
  end

  def present
    {
      id: @tag.id,
      name_en: @tag.name_en,
      name_ar: @tag.name_ar,
    }
  end
end
