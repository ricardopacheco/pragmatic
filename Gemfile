source "https://rubygems.org"

ruby "4.0.6"

gem "rails", "8.1.3.1"
gem "sqlite3", "2.9.6"
gem "puma", "8.0.2"
gem "thruster", "0.1.26", require: false
gem "bootsnap", "1.26.0", require: false

# json 3.x made JSON.parse options keyword-only, but ActiveSupport 8.1.3.1 still passes
# a positional hash (breaks reading the session cookie). Remove once Rails supports json 3.
gem "json", "2.21.2"

# Architecture tools
gem "dry-validation", "1.11.1"
gem "dry-monads", "1.11.0"
gem "dry-matcher", "1.0.0"
gem "burgundy", "2.0.0"

# Frontend tools

gem "propshaft", "1.3.2"
gem "importmap-rails", "2.2.3"
gem "turbo-rails", "2.0.23"
gem "stimulus-rails", "1.3.4"
gem "tailwindcss-rails", "4.6.0"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "3.1.22"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache", "1.0.10"
gem "solid_queue", "1.7.0"
gem "solid_cable", "4.0.2"

# Deploy tools
gem "kamal", "2.12.0", require: false

# Storage tools
gem "image_processing", "1.14.0"
gem "active_storage_validations", "4.1.1"

# Spreadsheet tools
gem "csv", "3.3.6"
gem "roo", "3.0.0"

group :development, :test do
  gem "pry-rails", "0.3.11"
  gem "factory_bot_rails", "6.5.1"
  gem "faker", "3.8.0"
end

group :development do
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", "8.0.6", require: false
  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", "0.9.3", require: false
  gem "rubycritic", "5.0.0", require: false
  # Standard runs RuboCop with a fixed ruleset; the plugins add the Rails and
  # performance cops on top of it.
  gem "standard", "1.56.0", require: false
  gem "standard-rails", "1.6.0", require: false
  gem "standard-performance", "1.9.0", require: false
end

group :test do
  gem "mocha", "3.1.0"
  gem "capybara", "3.40.0"
  gem "selenium-webdriver", "4.49.0"
  gem "simplecov", "1.3.0", require: false
end
