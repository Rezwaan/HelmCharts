class Admin::Presenters::Countries::Show
  def initialize(country)
    @country = country
  end

  def present
    {
      id: @country.id,
      name: @country.name,
    }
  end
end
