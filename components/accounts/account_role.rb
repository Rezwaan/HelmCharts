# == Schema Information
#
# Table name: account_roles
#
#  id                 :uuid             not null, primary key
#  role               :integer
#  role_resource_type :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :uuid
#  role_resource_id   :bigint
#
# Indexes
#
#  index_account_roles_on_account_id                               (account_id)
#  index_account_roles_on_role_resource_type_and_role_resource_id  (role_resource_type,role_resource_id)
#

class Accounts::AccountRole < ApplicationRecord
  belongs_to :account
  belongs_to :role_resource, polymorphic: true, optional: true

  validates :role, presence: true

  enum role: {
    admin: 1,
    reception: 2,

    content_entry: 3,
    content_quality: 4,
    brand_manager: 5,
    activation_manager: 6,
    integration_manager: 7,
  }

  scope :by_store_id, ->(id) {
    where("role_resource_type = ? AND role_resource_id = ?", Stores::Store.name, id)
  }
  scope :by_brand_id, ->(id) {
    where("role_resource_type = ? AND role_resource_id = ?", Brands::Brand.name, id)
  }
  scope :by_store_or_brand_id, ->(store_id, brand_id) {
    by_store_id(store_id).or(where("? IS NULL", brand_id)).or(by_brand_id(brand_id))
  }

  def global?
    role_resource_type.nil?
  end
end
