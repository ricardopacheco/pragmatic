# frozen_string_literal: true

module Guest
  # Never reveals whether the email is registered.
  class RequestPasswordResetContract < ApplicationContract
    params do
      required(:email).filled(:string)

      before(:value_coercer) do |result|
        result.to_h.compact_blank!
      end
    end

    rule(:email).validate(:email_format)
  end
end
