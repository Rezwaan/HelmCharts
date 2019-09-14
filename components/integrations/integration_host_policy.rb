class Integrations::IntegrationHostPolicy < ApplicationPolicy
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

  def integration_types?
    user.admin? || user.integration_manager?
  end

  def sync_stores?
    user.admin? || user.integration_manager?
  end

  def sync_catalog_list?
    user.admin? || user.integration_manager?
  end
end
