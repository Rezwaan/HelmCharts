require "rails_helper"

RSpec.describe Catalogs::CatalogSerializer do
  context "#menu serializes the menu" do
    it "removes disabled and invalid ids - case 1" do
      catalog_data = JSON.parse(file_fixture("catalogs/disabled-case-1.json").read)

      menu = Catalogs::CatalogSerializer.new(catalog_data, lang: "en").menu

      expect(menu[:categories][0][:product_ids].size).to eq(1)
      expect(menu[:categories][0][:product_ids][0]).to eq(123)

      expect(menu[:products].size).to eq(1)
      expect(menu[:products][0][:id]).to eq(123)
      expect(menu[:products][0][:disabled]).to be_nil
      expect(menu[:products][0][:bundle_ids].size).to eq(0)
    end

    it "removes disabled and invalid ids - case 2" do
      catalog_data = JSON.parse(file_fixture("catalogs/disabled-case-2.json").read)

      menu = Catalogs::CatalogSerializer.new(catalog_data, lang: "en").menu

      expect(menu[:items].size).to eq(1)
      expect(menu[:items][0][:id]).to eq(12345)
      expect(menu[:items][0][:customization_option_ids].size).to eq(1)
      expect(menu[:items][0][:customization_option_ids][0]).to eq(1234)

      expect(menu[:customization_options].size).to eq(1)
      expect(menu[:customization_options][0][:id]).to eq(1234)

      expect(menu[:customization_option_items].size).to eq(1)
      expect(menu[:customization_option_items][0][:id]).to eq(123)
    end
  end
end
