class Admin::Presenters::Manufacturers::Show
  def initialize(manufacturer)
    @manufacturer = manufacturer
  end

  def present
    {
      id: @manufacturer.id,
      name_en: @manufacturer.name_en,
      name_ar: @manufacturer.name_ar,
    }
  end
end
