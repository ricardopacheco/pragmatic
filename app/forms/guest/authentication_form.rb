# frozen_string_literal: true

module Guest
  class AuthenticationForm < ApplicationForm
    attr_reader :user

    attribute :email, :string
    attribute :password, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "Session")
    end

    def submit
      submit_with(Guest::AuthenticateOperation, attributes) { |user| @user = user }
    end
  end
end
