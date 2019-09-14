class Orders::OrderPolicy < ApplicationPolicy
  def marshal?
    user.admin?
  end
end
