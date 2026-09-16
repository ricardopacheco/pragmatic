# frozen_string_literal: true

module Profile
  class DeleteProfileOperation < ApplicationOperation
    def call(user_id)
      user = yield find_user(user_id)

      ActiveRecord::Base.transaction do
        yield delete_user_on_database(user)
        yield send_delete_profile_broadcast(user.id)
      end

      send_account_deleted_email(user)

      Success(nil)
    end

    private

    def send_delete_profile_broadcast(user_id)
      Success(Profile::DeleteProfileBroadcastJob.perform_later(user_id, request_id: Turbo.current_request_id))
    end
  end
end
