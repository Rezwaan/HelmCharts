require "securerandom"

module Accounts
  class AccountService
    include Common::Helpers::PaginationHelper

    class << self
      def generate_token(account, expiry: 24.hours)
        token = JWT.encode({account_id: account.id, exp: Time.now.to_i + expiry.to_i}, account.encrypted_password)

        {
          token: token,
          expiry: expiry.to_i,
        }
      end
    end

    def create(attributes)
      account = nil
      Accounts::Account.transaction do
        account = create_account(attributes)

        return account.errors unless account.save
      end

      create_dto(account)
    end

    def login(username:, password:, expiry: 4.hours)
      account = Accounts::Account.where(username: username).first

      return {error: "Username/Password doesn't match"} unless account

      if authenticate_account(username: username, password: password)
        return create_login_dto(account: account, expiry: expiry)
      end

      {error: "Username/Password doesn't match"}
    end

    def authenticate_account(username:, password:)
      account = Accounts::Account.where(username: username).first
      return nil unless account

      return account if account.valid_password?(password)

      nil
    end

    # Authenticate and return the account with associated roles
    # Return nil if roken is invalid
    def authenticate(token:)
      data = JWT.decode(token, nil, false).first
      account_id = data["account_id"]
      account = Accounts::Account.where(id: account_id).first

      if account
        begin
          res = JWT.decode token, account.encrypted_password, true
          if res.first["account_id"] == account.id # &&  account[:deleted_at].nil?
            return create_dto(account, light: false)
          end
        rescue
          return nil
        end
      end

      nil
    end

    def find(id:)
      account = Accounts::Account.where(id: id).not_deleted.first

      create_dto(account, light: false)
    end

    def fetch(id:)
      find(id: id)
    end

    def update(id:, attributes:)
      account = Accounts::Account.where(id: id).not_deleted.first
      return nil unless account

      account.assign_attributes(attributes.slice(*account_whitelist_attributes))

      return create_dto(account, light: false) if account.save

      account.errors
    end

    def destroy(id:)
      account = Accounts::Account.find_by(id: id)
      account.update_attributes(deleted_at: Time.now)

      create_dto(account)
    end

    def grant_role(account_id:, role:, role_resource_type: nil, role_resource_id: nil)
      account = Accounts::Account.find_by(id: account_id)
      account.roles.build(
        role: role,
        role_resource_type: role_resource_type,
        role_resource_id: role_resource_id,
      )

      return create_dto(account, light: false) if account.save

      account.errors
    end

    def revoke_role(account_role_id:)
      account_role = Accounts::AccountRole.find_by(id: account_role_id)
      account_role.destroy
    end

    def update_roles(account_id:, roles:)
      account = Accounts::Account.find_by(id: account_id)
      current_roles = Accounts::AccountRole.where(account_id: account_id).to_a
      roles_to_add = role_collection_diff(roles, current_roles)
      roles_to_remove = role_collection_diff(current_roles, roles)
      roles_to_add.each do |role|
        account.roles.build(
          role: role[:role],
          role_resource_type: role[:role_resource_type],
          role_resource_id: role[:role_resource_id],
        )
      end

      remove_ids = roles_to_remove.map { |role| role[:id] }
      account.save
      Accounts::AccountRole.where(id: remove_ids).destroy_all

      create_dto(account)
    end

    def filter(criteria: {}, page: 1, per_page: 50, sort_by: :id, sort_direction: "asc")
      accounts = Accounts::Account.not_deleted.includes(:roles)
      accounts = accounts.by_id(criteria[:id]) if criteria[:id].present?
      accounts = accounts.by_role_resource_type(criteria[:role_resource_type]) if criteria[:role_resource_type].present?
      accounts = accounts.by_role_resource_id(criteria[:role_resource_id]) if criteria[:role_resource_id].present?
      accounts = accounts.by_similar_name(criteria[:similar_name]) if criteria[:similar_name].present?
      accounts = accounts.by_similar_username(criteria[:similar_username]) if criteria[:similar_username].present?
      accounts = accounts.order(sort_by => sort_direction) if sort_by

      paginated_dtos(collection: accounts, page: page, per_page: per_page) do |account|
        create_dto(account)
      end
    end

    def account_ids_by_store(store:)
      return [] if store.blank?

      Accounts::AccountRole.by_store_or_brand_id(store.id, store.brand_id).pluck(:account_id).uniq
    end

    def generate_menu_token(catalog_id:)
      hmac_secret = Rails.application.secrets.menu_jwt[:hmac_secret]
      expiry_hours = Rails.application.secrets.menu_jwt[:expiry][:hours]
      expiry_minutes = Rails.application.secrets.menu_jwt[:expiry][:minutes]

      expiry = Time.now.to_i + expiry_hours.hours.to_i + expiry_minutes.minutes.to_i

      payload = {catalog_id: catalog_id, exp: expiry}
      JWT.encode payload, hmac_secret, "HS256"
    end

    def verify_menu_token(catalog_id:, token:)
      return false if token.blank?

      hmac_secret = Rails.application.secrets.menu_jwt[:hmac_secret]

      begin
        decoded = JWT.decode token, hmac_secret, true, {algorithm: "HS256"}
        return false unless decoded.first["catalog_id"] == catalog_id
        return true
      rescue JWT::ExpiredSignature
        return false
      end
    end

    def password_digest(account:)
      return unless account
      Accounts::Account.find_by(id: account.id).encrypted_password
    end

    private

    def basic_dto_hash(account)
      {
        id: account.id,
        username: account.username,
        name: account.name,
        email: email_format % {username: account.username},
        roles: roles_dto(account),
      }
    end

    def create_dto(account, light: true)
      return nil unless account

      attrs = basic_dto_hash(account)
      attrs[:roles] = roles_dto(account) unless light

      Accounts::AccountDTO.new(attrs)
    end

    def create_login_dto(account:, expiry:)
      token = JWT.encode(
        {account_id: account.id, exp: Time.now.to_i + expiry.to_i},
        account.encrypted_password
      )

      {
        token: token,
        expiry: expiry.to_i,
      }
    end

    def create_account(attributes)
      account = Accounts::Account.new
      account.name = attributes["name"]
      account.username = attributes["username"]
      account.password = attributes["password"]
      account
    end

    def apply_scope(criteria:)
      accounts = Accounts::Account.not_deleted
      accounts = accounts.by_partial_username(criteria[:username]) if criteria[:username].present?
      accounts
    end

    def account_whitelist_attributes
      %w[password name]
    end

    def roles_dto(account)
      account.roles.map do |role|
        role_dto(role)
      end
    end

    def role_dto(role)
      Accounts::AccountRoleDTO.new(
        id: role.id,
        role: role.role,
        role_resource_type: role.role_resource_type,
        role_resource_id: role.role_resource_id,
      )
    end

    def role_collection_diff(collection1, collection2)
      collection1.reject do |role1|
        collection2.any? do |role2|
          role1[:role] == role2[:role] &&
            role1[:role_resource_type] == role2[:role_resource_type] &&
            role1[:role_resource_id] == role2[:role_resource_id]
        end
      end
    end

    def email_format
      format = (Rails.application.secrets.accounts || {})[:email_format]
      format.present? ? format : "%{username}@lite.posdome.com"
    end
  end
end
