source "https://rubygems.org"

ruby "2.6.4"

# Ruby on Rails
gem "rails", "~> 5.2.3"
# Postgres support
gem "pg", "~> 1.1.4"
# TODO: Add why do we need this?
gem "activerecord-postgis-adapter", "~> 5.2.2"
# TODO: Add why do we need this?
gem "bcrypt", "~> 3.1.7"
# TODO: Add why do we need this?
gem "jwt", "~> 2.2.1"
# TODO: Add why do we need this?
gem "hawk-auth", "~> 0.2.5"
# Use Puma as the app server
gem "puma", "~> 4.1.1"
# Background workers
gem "sidekiq", "~> 5.2.7"
source "https://enterprise.contribsys.com/" do
  gem "sidekiq-pro", "~> 4.0.5"
  gem "sidekiq-ent", "~> 1.8.1"
end
# Scheduled background workers
gem "sidekiq-cron", "~> 1.1"
# NewRelic SDK for performance monitoring
gem "newrelic_rpm", "~> 6.6.0.358"
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false
# Pagination
gem "kaminari", "~> 1.1.1"
# Translations
gem "globalize", "~> 5.3.0"
gem "globalize-accessors", "~> 0.2.1"
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors", "~> 1.0.3"
# TODO: Add why do we need this?
gem "google-cloud-pubsub", "~> 0.39.1"
# TODO: Add why do we need this?
gem "google-cloud-firestore", "~> 1.1.0"
# TODO: Add why do we need this?
gem "paperclip", "~> 6.1.0"
# TODO: Add why do we need this?
gem "fog-google", "~> 1.9.1"
# TODO: Add why do we need this?
gem "prayer_times", "~> 0.1.3"
# TODO: Add why do we need this?
gem "faraday", "~> 0.15.4"
gem "faraday_middleware", "~> 0.13.1"
# Interact with SOAP webservices.
gem "savon", "~> 2.12.0"
# TODO: Add why do we need this?
gem "concurrent-ruby", "~> 1.1.5", require: "concurrent"
# TODO: Add why do we need this?
gem "httparty", "~> 0.17.0"
# TODO: Add why do we need this?
gem "httpclient", "~> 2.8.3"
# Expose metrics for Prometheus: https://github.com/discourse/prometheus_exporter
gem "prometheus_exporter", "~> 0.4.13"
# bit value
gem "flag_shih_tzu", "~> 0.3.23"
# Zendesk SDK
gem "zendesk_api", "~> 1.19.1"
# TODO: Add why do we need this?
gem "rgeo", "~> 2.1.1"
# TODO: Add why do we need this?
gem "rgeo-geojson", "~> 2.1.1"
# Deal with phone numbers and convert them to multiple different formats
gem "phony", "~> 2.18.7"
# Better logs for Rails
gem "lograge", "~> 0.11.2"
gem "lograge-sql", "~> 0.4.0"
# Soft delete
gem "discard", "~> 1.1.0"
# Authorization
gem "pundit", "~> 2.1.0"
# TODO: Add why do we need this?
gem "parallel", "~> 1.17"
# Sentry SDK for error reporting
gem "sentry-raven", "~> 2.11.1"
# To support PostgreSQL enum data types
gem "activerecord-postgres_enum", "~> 0.6.0"
# redis client
gem "redis", "~> 4.1.2"
# Authentication and Authorization
gem "devise", "~> 4.7.1"
# Gems from our GitHub Package Registry
# Validates Dome/Swyft catalogs
gem "catalog_schemas", "~> 1.0", source: "https://rubygems.pkg.github.com/themakersteam"

group :development do
  # TODO: Add why do we need this?
  gem "listen", ">= 3.0.5", "< 3.2"
  # Add annotations above models containing their current schema
  gem "annotate", "~> 2.7.5"
  # Code Style linter
  gem "standard", "~> 0.1.3"
end

group :test do
  # Rspec for testing
  gem "rspec-rails", "~> 3.8"
  # Generate ActiveRecord models.
  gem "factory_bot_rails", "~> 5.0.2"
  # Database cleaner for testing
  gem "database_cleaner", "~> 1.7.0"
  gem "factory_trace", "~> 0.3.2"
  # Control time
  gem "timecop", "~> 0.9.1"
  # Generate fake data for tests
  gem "faker", "~> 2.2.2"
  # Simple one-liner tests for common Rails functionality
  gem "shoulda-matchers", "~> 4.1.2"
end

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug", "~> 11.0.1", platforms: [:mri, :mingw, :x64_mingw]
  # Better printing using ap instead of puts
  gem "awesome_print", "~> 1.8.0"
  # Catch unoptimized queries
  gem "bullet", "~> 6.0.2"
end
