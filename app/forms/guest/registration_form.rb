# frozen_string_literal: true

module Guest
  class RegistrationForm < ApplicationForm
    attr_reader :user

    attribute :full_name, :string
    attribute :email, :string
    attribute :password, :string
    attribute :password_confirmation, :string
    attribute :avatar_image

    def self.model_name
      ActiveModel::Name.new(self, nil, "User")
    end

    def submit
      submit_with(Guest::RegisterOperation, attributes) { |user| @user = user }
    end
  end
end
