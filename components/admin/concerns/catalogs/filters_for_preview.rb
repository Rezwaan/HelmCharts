module Admin::Concerns::Catalogs::FiltersForPreview
  extend ActiveSupport::Concern

  included do
    skip_before_action :authenticate!, only: [:preview]
    skip_before_action :set_pagination, only: [:preview]
    skip_after_action :verify_authorized, only: [:preview] unless Rails.env.production?

    before_action :set_catalog, only: [:preview]
    before_action :authorize_preview, only: [:preview]
  end
end
