class Admin::ProductAttributeOptionsController < Admin::ApplicationController
  def index
    authorize(ProductCatalog::ProductAttributeOption)

    product_attribute_options_dto = ProductCatalog::ProductAttributeOptionService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
    )

    render json: {
      status: true,
      total_records: product_attribute_options_dto.total_count,
      total_pages: product_attribute_options_dto.total_pages,
      data: product_attribute_options_dto.map { |product_attribute_option_dto|
        Admin::Presenters::ProductAttributeOptions::Show.new(product_attribute_option_dto).present
      },
    }
  end
end
