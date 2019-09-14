class Companies::CompanyPolicy < ApplicationPolicy
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
end
