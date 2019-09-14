class Catalogs::CatalogPolicy < ApplicationPolicy
  def index?
    user.admin? || user.content_entry?
  end

  def show?
    user.admin? || user.content_entry?
  end

  def create?
    user.admin? || user.content_entry?
  end

  def token?
    user.admin? || user.content_entry?
  end

  def destroy?
    # user.admin? || user.content_entry?
    false
  end

  def assignments?
    user.admin? || user.content_quality?
  end

  def publish?
    user.admin? || user.content_quality?
  end

  def validate?
    user.admin? || user.content_quality?
  end
end
