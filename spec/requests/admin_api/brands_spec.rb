require "rails_helper"

RSpec.describe "Admin Brand Categories API", type: :request do
  let(:brand_manager_role) { build(:role, role: "brand_manager") }
  let(:brand_manager) { create(:account_with_role, role: brand_manager_role) }

  context "#index" do
    it "lists brand categories" do
      get_auth brand_manager, admin_brands_path

      expect(json).not_to be_empty
    end
  end

  context "#show" do
    let(:brand) { create(:brand, :with_category) }

    it "shows brand details" do
      get_auth brand_manager, admin_brand_path(brand.id)

      expect(json).not_to be_empty
    end
  end
end
