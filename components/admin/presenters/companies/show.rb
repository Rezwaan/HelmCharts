class Admin::Presenters::Companies::Show
  def initialize(company)
    @company = company
  end

  def present
    {
      id: @company.id,
      name_en: @company.name_en,
      name_ar: @company.name_ar,
      registration_number: @company.registration_number,
      country: {
        id: @company.country.dig(:id),
        name_en: @company.country.dig(:name_en),
        name_ar: @company.country.dig(:name_ar),
      },
    }
  end
end
