# frozen_string_literal: true

module Admin
  class CreateUserContract < ApplicationContract
    option :user_repo, default: proc { ::User }

    params do
      required(:full_name).filled(:string)
      required(:email).filled(:string)
      required(:role).filled(:string, included_in?: ::User.roles.keys)
      required(:password).filled(:string)
      required(:password_confirmation).filled(:string)
      optional(:avatar_image)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end

    rule(:full_name).validate(:full_name_format)
    rule(:email).validate(:email_format)
    rule(:email).validate(:email_not_taken)
    rule(:password).validate(:password_format)
    rule(:password, :password_confirmation).validate(:password_confirmation)
  end
end
