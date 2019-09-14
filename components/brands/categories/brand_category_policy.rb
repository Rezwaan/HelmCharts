class Brands::Categories::BrandCategoryPolicy < ApplicationPolicy
  def index?
    user.admin? || user.brand_manager?
  end

  def show?
    user.admin? || user.brand_manager?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end
end
