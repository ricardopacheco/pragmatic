# frozen_string_literal: true

# Validation rules shared by models and contracts, so both layers always agree.
Rails.application.configure do
  config.x.validations.full_name_length = 2..100
  config.x.validations.password_length = 8..72
  config.x.validations.email_format = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
end
