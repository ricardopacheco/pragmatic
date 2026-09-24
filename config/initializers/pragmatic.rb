# frozen_string_literal: true

if Rails.env.development?
  Faker::Config.locale = "pt"
  Faker::Config.random = Random.new(42)

  Rack::MiniProfiler.config.enable_hotwire_turbo_drive_support = true
  Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
end
