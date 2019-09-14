class Stores::StorePolicy < ApplicationPolicy
  def index?
    user.admin? || user.brand_manager?
  end

  def create?
    user.admin? || user.brand_manager?
  end

  def show?
    user.admin? || user.brand_manager?
  end

  def update?
    user.admin? || user.brand_manager?
  end

  def delete?
    user.admin?
  end

  def restore?
    user.admin?
  end

  def activate_pos?
    user.admin? || user.brand_manager?
  end

  def deactivate_pos?
    user.admin? || user.brand_manager?
  end

  def working_times?
    user.admin? || user.brand_manager?
  end
end
