# frozen_string_literal: true

module Guest
  class RegisterOperation < ApplicationOperation
    def call(attributes)
      validated = yield validate_contract(Guest::RegistrationContract, attributes)

      ActiveRecord::Base.transaction do
        @user = yield create_user_on_database(registration_attributes(validated))
        yield send_register_user_broadcast(@user.id)
      end

      Success(@user)
    end

    private

    # Visitors always register as regular users: the contract does not accept a role.
    def registration_attributes(validated)
      validated.to_h.merge(role: :profile)
    end

    def send_register_user_broadcast(user_id)
      Success(Guest::RegisterUserBroadcastJob.perform_later(user_id, request_id: Turbo.current_request_id))
    end
  end
end
