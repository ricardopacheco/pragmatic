# frozen_string_literal: true

module Profile
  class UpdateProfileForm < ApplicationForm
    attr_reader :user

    attribute :full_name, :string
    attribute :email, :string
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

    def submit(user_id)
      submit_with(Profile::UpdateProfileOperation, user_id, attributes) { |user| @user = user }
    end

    private

    def prefill(user)
      @user = user
      self.full_name = user.full_name if full_name.blank?
      self.email = user.email if email.blank?
    end
  end
end
