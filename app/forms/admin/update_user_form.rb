# frozen_string_literal: true

module Admin
  # Accepts user: to prefill the fields when rendering the form. Submitted values
  # always win over the ones read from the record.
  class UpdateUserForm < ApplicationForm
    attr_reader :user

    attribute :full_name, :string
    attribute :email, :string
    attribute :role, :string
    attribute :password, :string
    attribute :password_confirmation, :string
    attribute :avatar_image
    attribute :remove_avatar_image, :boolean

    def self.model_name
      ActiveModel::Name.new(self, nil, "User")
    end

    def initialize(attributes = {})
      attributes = attributes.to_h.symbolize_keys
      user = attributes.delete(:user)

      super

      prefill(user) if user
    end

    def submit(admin_id, user_id)
      submit_with(Admin::UpdateUserOperation, admin_id, user_id, attributes) { |user| @user = user }
    end

    private

    def prefill(user)
      @user = user
      self.full_name = user.full_name if full_name.blank?
      self.email = user.email if email.blank?
      self.role = user.role if role.blank?
    end
  end
end
