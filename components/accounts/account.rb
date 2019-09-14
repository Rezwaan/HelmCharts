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

class Accounts::Account < ApplicationRecord
  has_many :roles, class_name: Accounts::AccountRole.name
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable
  validates :name, :username, presence: true
  validates :username, uniqueness: {case_sensitive: false}

  scope :by_partial_username, ->(partial_username) {
    where("username ILIKE ?", "%#{partial_username}%")
  }
  scope :by_similar_name, ->(similar_name) {
    where("#{table_name}.name ILIKE ?", "%#{similar_name}%")
  }
  scope :by_similar_username, ->(similar_username) {
    where("#{table_name}.username ILIKE ?", "%#{similar_username}%")
  }
  scope :by_role_resource_type, ->(role_resource_type) {
    joins(:roles).where(account_roles: {role_resource_type: role_resource_type})
  }
  scope :by_role_resource_id, ->(role_resource_id) {
    joins(:roles).where(account_roles: {role_resource_id: role_resource_id})
  }
  scope :not_deleted, -> {
    where(deleted_at: nil)
  }

  def admin?
    roles.any? { |r| r.admin? && r.global? }
  end

  def content_entry?
    roles.any? { |r| r.content_entry? && r.global? }
  end

  def content_quality?
    roles.any? { |r| r.content_quality? && r.global? }
  end

  def brand_manager?
    roles.any? { |r| r.brand_manager? && r.global? }
  end

  def activation_manager?
    roles.any? { |r| r.activation_manager? && r.global? }
  end

  def integration_manager?
    roles.any? { |r| r.integration_manager? && r.global? }
  end

  def reception?
    roles.any? { |r| r.reception? && !r.global? }
  end

  def self.policy
    Accounts::AccountPolicy
  end
end
