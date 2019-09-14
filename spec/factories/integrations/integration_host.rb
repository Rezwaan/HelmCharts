FactoryBot.define do
  factory :integration_host, class: Integrations::IntegrationHost do
    name { Faker::Company.name }
    config { Faker::Json.shallow_json(width: 1, options: { key: 'Food.dish', value: 'Food.description' }) }
    integration_type { Integrations::IntegrationHost.integration_types.values.sample }
  end
end