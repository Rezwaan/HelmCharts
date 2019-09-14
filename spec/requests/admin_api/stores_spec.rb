require "rails_helper"

RSpec.describe "Admin Store API", type: :request do
  let(:admin_role) { build(:role, role: "admin") }
  let(:admin_account) { create(:account_with_role, role: admin_role) }

  context "#index" do
    let!(:stores) { create_list(:store, 10) }

    it "lists store" do
      get_auth admin_account, admin_stores_path

      expect(response).to have_http_status(:ok)
      expect(json).not_to be_empty
      expect(json["data"].size).to eq(stores.size)
    end
  end

  context "#show" do
    let(:store) { create(:store) }

    it "shows the details of a store" do
      get_auth admin_account, admin_store_path(store.id)

      expect(response).to have_http_status(:ok)
      expect(json).not_to be_empty
    end
  end
end
