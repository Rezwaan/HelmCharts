RSpec.describe Integrations::Br::Serializers::Hacks::LotusBiscoff do
  context "#build_catalog" do
    it "builds a catalog" do
      hack = Integrations::Br::Serializers::Hacks::LotusBiscoff.new

      catalog = hack.build_catalog(1)

      expect(catalog[:items].size).to eq(30)
      expect(catalog[:bundles].size).to eq(13)
      expect(catalog[:products].size).to eq(13)
      expect(catalog[:item_bundles].size).to eq(13)
      expect(catalog[:customization_options].size).to eq(13)
      expect(catalog[:customization_option_items].size).to eq(17)
    end
  end
end
