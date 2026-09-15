# frozen_string_literal: true

module Guest
  class AuthenticationContract < ApplicationContract
    option :user_repo, default: proc { ::User }

    params do
      required(:email).filled(:string)
      required(:password).filled(:string)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end

    rule(:email).validate(:email_format)

    rule(:email, :password) do |context:|
      next if rule_error?(:email)

      context[:user] ||= user_repo.authenticate_by(email: values[:email], password: values[:password])
      next if context[:user]

      base.failure(I18n.t("contracts.errors.custom.authentication.invalid_credentials"))
    end
  end
end
