# frozen_string_literal: true

module Profile
  class UpdatePasswordForm < ApplicationForm
    attribute :current_password, :string
    attribute :password, :string
    attribute :password_confirmation, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "User")
    end

    def submit(user_id)
      submit_with(Profile::UpdatePasswordOperation, user_id, attributes)
    end
  end
end
