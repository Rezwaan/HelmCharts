class Accounts::AccountPolicy < ApplicationPolicy
  def index?
    user.admin? || user.activation_manager?
  end

  def show?
    user.admin? || user.activation_manager?
  end

  def create?
    user.admin? || user.activation_manager?
  end

  def update?
    user.admin? || user.activation_manager?
  end

  def destroy?
    user.admin?
  end
end
