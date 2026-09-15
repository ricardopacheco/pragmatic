# frozen_string_literal: true

module Profile
  class DeleteProfileOperation < ApplicationOperation
    def call(user_id)
      user = yield find_user(user_id)

      ActiveRecord::Base.transaction do
        yield delete_user_on_database(user)
      end

      send_account_deleted_email(user)

      Success(nil)
    end
  end
end
