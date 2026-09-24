# frozen_string_literal: true

if Rails.env.development?
  Faker::Config.locale = "pt"
  Faker::Config.random = Random.new(42)
end
