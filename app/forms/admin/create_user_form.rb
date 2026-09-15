# frozen_string_literal: true

module Admin
  class CreateUserForm < ApplicationForm
    attr_reader :user

    attribute :full_name, :string
    attribute :email, :string
    attribute :role, :string
    attribute :password, :string
    attribute :password_confirmation, :string
    attribute :avatar_image

    def self.model_name
      ActiveModel::Name.new(self, nil, "User")
    end

    def submit(admin_id)
      submit_with(Admin::CreateUserOperation, admin_id, attributes) { |user| @user = user }
    end
  end
end
