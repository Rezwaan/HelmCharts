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

FactoryBot.define do
  factory :account_role, class: Accounts::AccountRole, aliases: [:role] do
    add_attribute(:role) { "admin" }

    trait :for_account do
      association :account
    end

    factory :reception_role do
      add_attribute(:role) { "reception" }

      trait :for_store do
        association :role_resource, factory: :store
      end
    end
  end
end
