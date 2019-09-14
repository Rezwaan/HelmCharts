require "rails_helper"

RSpec.describe "Admin Catalogs API", type: :request do
  let(:admin_role) { build(:role, role: "admin") }
  let(:admin_account) { create(:account_with_role, role: admin_role) }

  context "#index" do
    let(:catalogs) { create_list(:catalog, 20) }

    it "lists catalogs" do
      get_auth admin_account, admin_catalogs_path

      expect(json).to_not be_empty
    end
  end

  context "#token" do
    it "return 404 for not existing catalog" do
      get_auth admin_account, token_admin_catalog_path(1234)

      expect(response).to have_http_status(:not_found)
    end
  end
end
