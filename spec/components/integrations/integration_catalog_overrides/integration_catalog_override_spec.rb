RSpec.describe Integrations::IntegrationCatalogOverride, type: :model do
  context "relations" do
    it { should belong_to(:catalog)
                .class_name(Integrations::IntegrationCatalog.name)
                .with_foreign_key(:integration_catalog_id)
                .required()
    }
  end

  context "validations" do
    it { should validate_presence_of(:item_id) }

    it { should validate_presence_of(:item_type) }
    it { should validate_inclusion_of(:item_type)
                .in_array(Integrations::IntegrationCatalogOverride::ITEM_TYPES)
    }

    it { should validate_presence_of(:properties) }
    it { should validate_length_of(:properties).is_at_least(1) }
  end
end
