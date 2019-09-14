require "rails_helper"

RSpec.describe "Admin Sessions API", type: :request do
  let(:admin_role) { build(:role, role: "admin") }
  let(:admin_account) { create(:account_with_role, role: admin_role) }

  context "#create" do
    it "creates a token" do
      post admin_sessions_path, params: {
        username: admin_account.username,
        password: admin_account.password,
      }

      expect(response).to have_http_status(:ok)
      expect(json).not_to be_empty
      expect(json["token"]).not_to be_empty
      expect(json["expiry"]).to eq(24.hours)
    end

    let(:deleted_account) { create(:account, deleted_at: DateTime.now) }

    it "dose not allow deleted accounts" do
      post admin_sessions_path, params: {
        username: deleted_account.username,
        password: deleted_account.password,
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "#me" do
    it "displays user info" do
      get_auth admin_account, me_admin_sessions_path

      expect(response).to have_http_status(:ok)
      expect(json["account"]["username"]).to eq(admin_account.username)
      expect(json["account"]["roles"].size).to eq(1)
    end
  end
end
