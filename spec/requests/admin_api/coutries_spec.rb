require "rails_helper"

RSpec.describe "Admin Countries API", type: :request do
  let(:account) { create(:account) }

  context "#index" do
    it "lists brand categories" do
      get_auth account, admin_countries_path

      expect(json).not_to be_empty
    end
  end
end
