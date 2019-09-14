require "rails_helper"

RSpec.describe "Admin Account Roles API", type: :request do
  let(:admin_role1) { build(:role, role: "admin") }
  let(:admin_account1) { create(:account_with_role, role: admin_role1) }
  let(:admin_role2) { build(:role, role: "admin") }
  let(:admin_account2) { create(:account_with_role, role: admin_role2) }

  context "#create" do
    it "grants a new role" do
      post_auth admin_account1, admin_account_account_roles_path(admin_account2), params: {
        role: "brand_manager",
      }

      expect(response).to have_http_status(:ok)
      expect(json["roles"].size).to eq(2)
      expect(json["roles"].last["role"]).to eq("brand_manager")
    end
  end

  context "#destroy" do
    it "removes a role from a user" do
      delete_auth admin_account1, admin_account_account_role_path(admin_account2, admin_role2)

      expect(response).to have_http_status(:ok)
      expect(json["roles"].size).to eq(0)
    end
  end
end
