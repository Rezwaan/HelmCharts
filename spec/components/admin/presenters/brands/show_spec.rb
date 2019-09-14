require "rails_helper"

RSpec.describe Admin::Presenters::Brands::Show do
  context "#present" do
    let!(:category) { create(:brand_category, :named) }
    let!(:brand) { create(:brand, :with_category, brand_category: category) }

    it "present a brand" do
      b = Admin::Presenters::Brands::Show.new(brand).present

      expect(b[:id]).to eq(brand.id)
      expect(b[:name]).to eq(brand.name)
      expect(b[:name_ar]).to eq(brand.name_ar)
      expect(b[:name_en]).to eq(brand.name_en)
      expect(b[:logo_url]).to eq(brand.logo_url)
      expect(b[:backend_id]).to eq(brand.backend_id)
      expect(b[:approved]).to eq(brand.approved)
      expect(b[:contracted]).to eq(brand.contracted)

      expect(b[:brand_category][:id]).to eq(category.id)
      expect(b[:brand_category][:key]).to eq(category.key)
      expect(b[:brand_category][:name]).to eq(category.name)
      expect(b[:brand_category][:name_ar]).to eq(category.name_ar)
      expect(b[:brand_category][:name_en]).to eq(category.name_en)
      expect(b[:brand_category][:plural_name]).to eq(category.plural_name)
      expect(b[:brand_category][:plural_name_ar]).to eq(category.plural_name_ar)
      expect(b[:brand_category][:plural_name_en]).to eq(category.plural_name_en)
    end
  end
end
