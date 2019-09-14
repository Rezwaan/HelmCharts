class Admin::CatalogsController < Admin::ApplicationController
  include Concerns::Catalogs::FiltersForPreview

  def index
    authorize(Catalogs::Catalog)

    catalogs_dto = Catalogs::CatalogService.new.filter(
      criteria: params.dig(:criteria) || {},
      per_page: @per_page,
      page: @page,
      sort_direction: @sort_direction,
      sort_by: params[:sort_by],
      light: false,
    )

    render json: {
      status: true,
      total_records: catalogs_dto.total_count,
      total_pages: catalogs_dto.total_pages,
      data: catalogs_dto.map { |catalog_dto|
        Admin::Presenters::Catalogs::Show.new(catalog_dto).present
      },
    }
  end

  def show
    authorize(Catalogs::Catalog)

    catalog = Catalogs::CatalogService.new.fetch(params[:id], light: false)
    return head :not_found if catalog.nil?

    bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
    firebase_config = bot.app_config
    firebase_config[:token] = bot.generate_auth_token(catalog.id, {'token_scope': "catalog"})

    render json: Admin::Presenters::Catalogs::Show.new(catalog).present(firebase_config: firebase_config)
  end

  def create
    authorize(Catalogs::Catalog)

    catalog = Catalogs::CatalogService.new.create(attributes: params)

    return render json: {error: catalog.messages}, status: :unprocessable_entity if catalog.is_a?(ActiveModel::Errors)

    render json: Admin::Presenters::Catalogs::Show.new(catalog).present
  end

  def token
    authorize(Catalogs::Catalog)

    catalog = Catalogs::CatalogService.new.fetch(params[:id], light: true)

    return render json: {error: "not found"}, status: :not_found unless catalog

    bot = Firebase::Bot.new(config: Rails.application.secrets.firebase)
    firebase_config = bot.app_config
    firebase_config[:token] = bot.generate_auth_token(catalog.id, {'token_scope': "catalog"})

    token = Accounts::AccountService.new.generate_menu_token(catalog_id: catalog.id)
    menu_url_en = preview_admin_catalog_url(catalog.id, token: token, language: "en")
    menu_url_ar = preview_admin_catalog_url(catalog.id, token: token, language: "ar")

    render json: Admin::Presenters::Catalogs::Token.new(catalog).present(firebase_config: firebase_config, menu_url_en: menu_url_en, menu_url_ar: menu_url_ar)
  end

  def destroy
    authorize(Catalogs::Catalog)

    res = Catalogs::CatalogService.new.delete(params[:id])
    return head :unprocessable_entity unless res

    head :ok
  end

  def assignments
    authorize(Catalogs::Catalog)

    assignments = Catalogs::CatalogAssignmentService.new.update_assignments(
      id: params[:id],
      assignments: params[:assignments],
    )

    render json: assignments
  end

  def publish
    authorize(Catalogs::Catalog)

    catalog = Catalogs::CatalogService.new.publish(params[:id], {account_id: @current_account.id, username: @current_account.username, name: @current_account.name})

    return head :not_found if catalog.nil?

    # TODO: Return this once our validator setup is done and we're sure we've done
    # the necessary changes to catalog structure.
    # TODO: Enhance this to be more readable
    # Catalog is actually an errors array in this case
    # return render(json: {error: catalog}, status: :unprocessable_entity) if catalog.is_a?(Array)

    render json: Admin::Presenters::Catalogs::Show.new(catalog).present
  end

  def preview
    menu = Catalogs::CatalogService.new.catalog_preview(catalog: @catalog, language: params[:language])

    return render json: {message: "Menu not found"}, status: :not_found unless menu[:data].present?
    render json: menu
  end

  def validate
    authorize(Catalogs::Catalog)
    catalog = params[:catalog]&.to_unsafe_h

    catalog_service = Catalogs::CatalogService.new
    errors = catalog_service.validate_catalog(catalog)

    render(json: {errors: errors})
  end

  private

  def authorize_preview
    verified = Accounts::AccountService.new.verify_menu_token(catalog_id: @catalog.id, token: params[:token])

    return head :unauthorized unless verified
  end

  def set_catalog
    @catalog = Catalogs::CatalogService.new.fetch(params[:id])

    head :not_found if @catalog.nil?
  end
end
