# frozen_string_literal: true

module Guest
  class ResetPasswordOperation < ApplicationOperation
    def call(attributes)
      validated = yield validate_contract(Guest::ResetPasswordContract, attributes)
      user = validated.context[:user]

      ActiveRecord::Base.transaction do
        yield update_user_on_database(user, password_attributes(validated))
        yield terminate_sessions(user)
      end

      Success(user)
    end

    private

    def password_attributes(validated)
      validated.to_h.slice(:password, :password_confirmation)
    end

    # A password reset signs the user out everywhere.
    def terminate_sessions(user)
      user.sessions.destroy_all

      Success(Sessions::DeleteSessionBroadcastJob.perform_later(user.id))
    end
  end
end
