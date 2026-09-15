# frozen_string_literal: true

module Guest
  # Always succeeds, so the response never reveals whether the email is registered.
  class RequestPasswordResetOperation < ApplicationOperation
    def call(attributes)
      validated = yield validate_contract(Guest::RequestPasswordResetContract, attributes)

      send_password_reset_email(validated[:email])

      Success(nil)
    end

    private

    def send_password_reset_email(email)
      user = User.find_by(email:)

      Guest::PasswordsMailer.reset(user).deliver_later if user.present?
    end
  end
end
