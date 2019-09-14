# == Schema Information
#
# Table name: accounts
#
#  id                     :uuid             not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  deleted_at             :datetime
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           default(""), not null
#  old_password_digest    :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  unconfirmed_email      :string
#  username               :string           default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_accounts_on_confirmation_token    (confirmation_token) UNIQUE
#  index_accounts_on_reset_password_token  (reset_password_token) UNIQUE
#  index_accounts_on_username              (username) UNIQUE
#

FactoryBot.define do
  factory :account, class: Accounts::Account do
    name { Faker::Name.name }
    username { Faker::Alphanumeric.alpha }
    password { Faker::Alphanumeric.alphanumeric }

    factory :account_with_role do
      transient do
        role { build(:reception_role) }
      end

      after(:create) do |account, evaluator|
        evaluator.role.account_id = account.id
        evaluator.role.save
      end
    end
  end
end
