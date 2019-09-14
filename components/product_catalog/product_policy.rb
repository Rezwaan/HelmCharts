class ProductCatalog::ProductPolicy < ApplicationPolicy
  def index?
    user.admin? || user.content_entry?
  end

  def show?
    user.admin? || user.content_entry?
  end

  def create?
    user.admin? || user.content_entry?
  end

  def update?
    user.admin? || user.content_entry?
  end
end
