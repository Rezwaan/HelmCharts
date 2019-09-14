class Companies::CompanyService
  include Common::Helpers::PaginationHelper

  def create(attributes:)
    company = Companies::Company.new(attributes)

    if company.save
      return create_dto(company)
    else
      return company.errors.full_messages.join(", ")
    end
  end

  def update(company_id:, attributes:)
    company = Companies::Company.find_by(id: company_id)

    if company.update(attributes)
      return create_dto(company)
    else
      return company.errors.full_messages.join(", ")
    end
  end

  def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
    companies = Companies::Company.not_deleted
    companies = companies.by_id(criteria[:id]) if criteria[:id].present?
    companies = companies.where(registration_number: criteria[:registration_number]) if criteria[:registration_number].present?
    companies = companies.by_country(criteria[:country_id]) if criteria[:country_id].present?
    companies = companies.by_name(criteria[:name]) if criteria[:name].present?
    companies = companies.by_country_name(criteria[:country_name]) if criteria[:country_name].present?
    companies = companies.order(sort_by => sort_direction) if sort_by

    companies = companies.includes(:translations, country: :translations)

    paginated_dtos(collection: companies, page: page, per_page: per_page) do |company|
      create_dto(company)
    end
  end

  def fetch(id)
    company = Companies::Company.where(id: id).not_deleted.first
    return nil unless company
    create_dto(company)
  end

  def delete(id)
    company = Companies::Company.where(id: id).not_deleted.first
    return nil unless company

    if company&.destroy
      return create_dto(company)
    else
      return company.errors.full_messages.join(", ")
    end
  end

  private

  def create_dto(company)
    Companies::CompanyDTO.new({
      id: company.id,
      name_en: company.name_en,
      name_ar: company.name_ar,
      registration_number: company.registration_number,
      country: {
        id: company.country&.id,
        name_en: company.country&.name_en,
        name_ar: company.country&.name_ar,
      },
    })
  end
end
