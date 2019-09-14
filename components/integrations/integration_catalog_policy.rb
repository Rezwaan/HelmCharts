class Integrations::IntegrationCatalogPolicy < ApplicationPolicy
  def index?
    user.admin? || user.integration_manager?
  end

  def show?
    user.admin? || user.integration_manager?
  end

  def link_to_catalog?
    user.admin? || user.integration_manager?
  end

  def sync_catalog?
    user.admin? || user.integration_manager?
  end
end
