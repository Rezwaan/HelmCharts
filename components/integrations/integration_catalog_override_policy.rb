class Integrations::IntegrationCatalogOverridePolicy < ApplicationPolicy
  def index?
    user.admin? || user.integration_manager?
  end

  def show?
    user.admin? || user.integration_manager?
  end

  def create?
    user.admin? || user.integration_manager?
  end

  def update?
    user.admin? || user.integration_manager?
  end

  def destroy?
    user.admin? || user.integration_manager?
  end
end
