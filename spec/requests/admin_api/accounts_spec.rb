require "rails_helper"

RSpec.describe "Admin Accounts API", type: :request do
  let(:admin_role) { build(:role, role: "admin") }
  let(:admin) { create(:account_with_role, role: admin_role) }
  let(:regular_account) { create(:account) }

  context "#index" do
    let!(:accounts) { create_list(:account_with_role, 10, role: admin_role) }

    it "lists accounts" do
      get_auth admin, admin_accounts_path

      expect(json["data"].size).to eq(accounts.size + 1)
    end
  end

  context "#create" do
    let!(:attributes) { attributes_for(:account) }

    it "creates an account" do
      post_auth admin, admin_accounts_path, params: attributes

      expect(response).to have_http_status(:ok)
      expect(json).not_to be_empty
      expect(json["username"]).to eq(attributes[:username])
    end

    it "prevents duplicate username" do
      post_auth admin, admin_accounts_path, params: admin.attributes

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires permissions" do
      post_auth regular_account, admin_accounts_path, params: attributes

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "#destory" do
    let!(:account) { create(:account) }

    it "soft deletes a user" do
      delete_auth admin, admin_account_path(account.id)

      expect(response).to have_http_status(:ok)
      expect(account.deleted_at).to be_nil

      expect(Accounts::Account.find(account.id).id).to eq(account.id)
    end
  end
end
