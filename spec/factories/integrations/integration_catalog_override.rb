FactoryBot.define do
  factory :integration_catalog_override, class: Integrations::IntegrationCatalogOverride do
    association :catalog, factory: :integration_catalog

    item_id { Faker::Internet.uuid }
    item_type { Integrations::IntegrationCatalogOverride::ITEM_TYPES.sample }
    properties { {reference_name: Faker::Food.dish} }
  end
end