# frozen_string_literal: true

module Profile
  class UpdatePasswordContract < ApplicationContract
    params do
      required(:current_password).filled(:string)
      required(:password).filled(:string)
      required(:password_confirmation).filled(:string)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end

    rule(:password).validate(:password_format)
    rule(:password, :password_confirmation).validate(:password_confirmation)

    rule(:current_password) do |context:|
      next if context[:user]&.authenticate(value)

      key.failure(I18n.t("errors.messages.invalid"))
    end
  end
end
