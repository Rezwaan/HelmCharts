class Countries::CountryPolicy < ApplicationPolicy
  def index?
    user.present?
  end
end
