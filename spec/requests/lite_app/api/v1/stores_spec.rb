require "rails_helper"

RSpec.describe "Lite Stores API", type: :request do
  let!(:regular_account) { create(:account) }
  let!(:store_reception_role) { build(:reception_role, :for_store) }
  let!(:store_reception_account) { create(:account_with_role, role: store_reception_role) }

  context "#index" do
    let(:stores) { create_list(:store, 20) }

    it "requires access to stores" do
      get_auth regular_account, lite_app_api_v1_stores_path, params: {}

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to be_empty
    end

    it "lists stores" do
      get_auth store_reception_account, lite_app_api_v1_stores_path, params: {}

      expect(response).to have_http_status(:ok)
      expect(json["total_records"]).to eq(1)
      expect(json["data"][0]["name"]).to eq(store_reception_account.roles[0].role_resource.name)
    end

    it "paginates stores" do
      stores.each do |store|
        create(:reception_role, :for_store, :for_account, role_resource: store, account: store_reception_account)
      end

      get_auth store_reception_account, lite_app_api_v1_stores_path, params: {per_page: 10}
      expect(json["total_records"]).to eq(21)
      expect(json["data"].size).to eq(10)
    end
  end
end
