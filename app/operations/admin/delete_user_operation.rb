# frozen_string_literal: true

module Admin
  class DeleteUserOperation < ApplicationOperation
    def call(admin_id, user_id)
      yield find_and_validate_user_admin(admin_id)
      user = yield find_user(user_id)

      ActiveRecord::Base.transaction do
        yield delete_user_on_database(user)
      end

      send_account_deleted_email(user)

      Success(nil)
    end
  end
end
