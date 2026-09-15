# frozen_string_literal: true

module Guest
  class RequestPasswordResetForm < ApplicationForm
    attribute :email, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "Password")
    end

    def submit
      submit_with(Guest::RequestPasswordResetOperation, attributes)
    end
  end
end
