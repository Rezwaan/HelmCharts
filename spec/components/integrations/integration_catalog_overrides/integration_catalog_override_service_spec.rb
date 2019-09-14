RSpec.describe Integrations::IntegrationCatalogOverrideService do
  let (:service) { Integrations::IntegrationCatalogOverrideService }

  context "#apply_overrides" do
    let(:integration_catalog) { create(:integration_catalog) }
    let(:serialized_catalog_with_integer_ids) {
      {
        name: "A catalog for testing",
        sets: {},
        items: {},
        bundles: {},
        products: {
          1 => {
            id: 1,
            reference_name: "Burger",
            name: "Burger",
            name_ar: "برغر",
            images: {},
            weight: 1,
            description: "Burger with provolone cheese",
            description_ar: "برغر مع جبنة بروفولون",
            bundle_ids: {},
          },
        },
        item_sets: {},
        categories: {},
        bundle_sets: {},
        item_bundles: {},
        customization_options: {},
        customization_ingredients: {},
        customization_option_items: {},
        customization_ingredient_items: {},
      }
    }

    let(:serialized_catalog_with_string_ids) {
      {
        name: "A catalog for testing",
        sets: {},
        items: {},
        bundles: {},
        products: {
          "1" => {
            id: 1,
            reference_name: "Burger",
            name: "Burger",
            name_ar: "برغر",
            images: {},
            weight: 1,
            description: "Burger with provolone cheese",
            description_ar: "برغر مع جبنة بروفولون",
            bundle_ids: {},
          },
        },
        item_sets: {},
        categories: {},
        bundle_sets: {},
        item_bundles: {},
        customization_options: {},
        customization_ingredients: {},
        customization_option_items: {},
        customization_ingredient_items: {},
      }
    }

    context "valid overrides" do
      before(:each) do
        create(
          :integration_catalog_override,
          catalog: integration_catalog,
          item_type: "products",
          item_id: "1",
          properties: {
            name: "Pizza",
            images: {"a" => "http://example.com/a.jpg"},
          }
        )
      end

      it "should apply overrides for catalog with string item IDs" do
        overridden_catalog = service.apply_overrides(
          integration_catalog_id: integration_catalog.id,
          catalog: serialized_catalog_with_string_ids
        )

        expected_product = {
          id: 1,
          reference_name: "Burger",
          name: "Pizza",
          name_ar: "برغر",
          images: {"a" => "http://example.com/a.jpg"},
          weight: 1,
          description: "Burger with provolone cheese",
          description_ar: "برغر مع جبنة بروفولون",
          bundle_ids: {},
        }.with_indifferent_access

        expect(overridden_catalog[:products]["1"]).to eq(expected_product)
      end

      it "should apply overrides for catalog with integer item IDs" do
        overridden_catalog = service.apply_overrides(
          integration_catalog_id: integration_catalog.id,
          catalog: serialized_catalog_with_integer_ids
        )

        expected_product = {
          id: 1,
          reference_name: "Burger",
          name: "Pizza",
          name_ar: "برغر",
          images: {"a" => "http://example.com/a.jpg"},
          weight: 1,
          description: "Burger with provolone cheese",
          description_ar: "برغر مع جبنة بروفولون",
          bundle_ids: {},
        }.with_indifferent_access

        expect(overridden_catalog[:products][1]).to eq(expected_product)
      end
    end
  end
end
