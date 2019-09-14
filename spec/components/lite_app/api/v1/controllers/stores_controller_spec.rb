require "rails_helper"

RSpec.describe LiteApp::Api::V1::StoresController, type: :controller do
  let(:device) { build_stubbed(Devices::Device) }

  context "GET #summary_report" do
    it "fails when unauthenticated" do
      get :summary_report, params: {
        page: "1",
        store_ids: {
          "1": "1",
        },
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "passes when authenticated" do
      get :summary_report, params: {
        page: "1",
        store_ids: {
          "1": "1",
        },
      }
      # asd
    end
  end
end
