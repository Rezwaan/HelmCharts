class AppVersions::AppVersionPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def search?
    user.admin?
  end

  def update?
    user.admin?
  end

  def bulk_update?
    user.admin?
  end

  def enum_options?
    user.admin?
  end
end
