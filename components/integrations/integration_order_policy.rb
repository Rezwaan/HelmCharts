class Integrations::IntegrationOrderPolicy < ApplicationPolicy
  def index?
    user.admin? || user.integration_manager?
  end

  def show?
    user.admin? || user.integration_manager?
  end

  def update?
    user.admin? || user.integration_manager?
  end

  def link_to_store?
    user.admin? || user.integration_manager?
  end
end
