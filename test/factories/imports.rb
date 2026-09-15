# frozen_string_literal: true

FactoryBot.define do
  factory :import do
    user factory: %i[user admin]
    spreadsheet do
      Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/users.csv"), "text/csv")
    end

    trait :xlsx do
      spreadsheet do
        Rack::Test::UploadedFile.new(
          Rails.root.join("test/fixtures/files/users.xlsx"),
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end

    trait :missing_headers do
      spreadsheet do
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/users_missing_headers.csv"), "text/csv")
      end
    end

    trait :malformed do
      spreadsheet do
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/users_malformed.csv"), "text/csv")
      end
    end

    trait :batch do
      spreadsheet do
        Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/users_batch.csv"), "text/csv")
      end
    end
  end
end
