# frozen_string_literal: true

module Profile
  class UpdatePasswordOperation < ApplicationOperation
    def call(user_id, attributes)
      user = yield find_user(user_id)
      validated = yield validate_contract(Profile::UpdatePasswordContract, attributes, user:)

      yield update_user_on_database(user, password_attributes(validated))

      Success(user)
    end

    private

    def password_attributes(validated)
      validated.to_h.slice(:password, :password_confirmation)
    end
  end
end
