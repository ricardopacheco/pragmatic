# frozen_string_literal: true

module Guest
  class AuthenticateOperation < ApplicationOperation
    def call(attributes)
      validated = yield validate_contract(Guest::AuthenticationContract, attributes)

      Success(validated.context[:user])
    end
  end
end
