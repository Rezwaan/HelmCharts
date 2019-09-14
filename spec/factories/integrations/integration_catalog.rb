FactoryBot.define do
  factory :integration_catalog, class: Integrations::IntegrationCatalog do
    association :integration_host

    external_data { Faker::Json.shallow_json(width: 1, options: { key: 'Food.dish', value: 'Food.description' }) }
    external_reference { Faker::Internet.uuid }
  end
end