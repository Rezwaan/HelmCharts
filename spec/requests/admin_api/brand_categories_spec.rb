require "rails_helper"

RSpec.describe "Admin Brand Categories API", type: :request do
  let(:admin_role) { build(:role, role: "admin") }
  let(:admin) { create(:account_with_role, role: admin_role) }

  context "#index" do
    it "lists brand categories" do
      get_auth admin, admin_brand_categories_path

      expect(response).to have_http_status(:ok)
      expect(json).not_to be_empty
    end
  end
end
