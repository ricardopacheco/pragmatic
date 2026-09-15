# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    full_name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { password }
    role { "profile" }

    trait :admin do
      role { "admin" }
    end
  end
end
