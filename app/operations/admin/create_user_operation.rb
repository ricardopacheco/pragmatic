# frozen_string_literal: true

module Admin
  class CreateUserOperation < ApplicationOperation
    def call(admin_id, attributes)
      yield find_and_validate_user_admin(admin_id)
      validated = yield validate_contract(Admin::CreateUserContract, attributes)

      ActiveRecord::Base.transaction do
        @user = yield create_user_on_database(validated.to_h)
      end

      Success(@user)
    end
  end
end
