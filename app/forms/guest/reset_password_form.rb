# frozen_string_literal: true

module Guest
  class ResetPasswordForm < ApplicationForm
    attr_reader :user

    attribute :token, :string
    attribute :password, :string
    attribute :password_confirmation, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "Password")
    end

    def submit
      submit_with(Guest::ResetPasswordOperation, attributes) { |user| @user = user }
    end
  end
end
