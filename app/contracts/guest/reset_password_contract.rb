# frozen_string_literal: true

module Guest
  class ResetPasswordContract < ApplicationContract
    option :user_repo, default: proc { ::User }

    params do
      required(:token).filled(:string)
      required(:password).filled(:string)
      required(:password_confirmation).filled(:string)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end

    rule(:password).validate(:password_format)
    rule(:password, :password_confirmation).validate(:password_confirmation)

    rule(:token) do |context:|
      context[:user] ||= user_repo.find_by_password_reset_token(value)
      next if context[:user]

      base.failure(I18n.t("contracts.errors.custom.password_reset.invalid_token"))
    end
  end
end
