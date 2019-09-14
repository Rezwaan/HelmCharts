require "rails_helper"

RSpec.describe "Admin Companies API", type: :request do
  let(:brand_manager_role) { build(:role, role: "brand_manager") }
  let(:brand_manager) { create(:account_with_role, role: brand_manager_role) }
  let(:regular_account) { create(:account) }

  let!(:attributes) { attributes_for(:company) }

  context "#index" do
    it "lists companies" do
      create_list(:company, 10)

      get_auth brand_manager, admin_companies_path

      expect(json["data"].count).to eq(10)
      expect(json["total_records"]).to eq(10)
    end

    it "enforces authorization" do
      post_auth regular_account, admin_companies_path, params: attributes

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "#create" do
    it "creates a company" do
      post_auth brand_manager, admin_companies_path, params: attributes

      expect(response).to have_http_status(:created)
    end

    it "enforces  unique names" do
      company = create(:company)
      post_auth brand_manager, admin_companies_path, params: attributes.merge(name_en: company.name_en)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to eq({"error" => "Name has already been taken"})
    end

    it "enforces authorization" do
      post_auth regular_account, admin_companies_path, params: attributes

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "#update" do
    it "prevents duplication" do
      company = create(:company)
      put_auth brand_manager, admin_company_path(company.id), params: attributes.merge(name_en: company.name_en)
    end

    it "enforces authorization" do
      post_auth regular_account, admin_companies_path, params: attributes

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "#show" do
    let!(:company) { create(:company) }

    it "company" do
      get_auth brand_manager, admin_company_path(company.id)

      expect(json["id"]).to eq(company.id)
      expect(json["name_ar"]).to eq(company.name_ar)
      expect(json["name_ar"]).to eq(company.name_ar)
    end
  end
end
