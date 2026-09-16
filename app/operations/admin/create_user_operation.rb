# frozen_string_literal: true

module Admin
  class CreateUserOperation < ApplicationOperation
    def call(admin_id, attributes)
      yield find_and_validate_user_admin(admin_id)
      validated = yield validate_contract(Admin::CreateUserContract, attributes)

      ActiveRecord::Base.transaction do
        @user = yield create_user_on_database(validated.to_h)
        yield send_create_user_broadcast(@user.id)
      end

      Success(@user)
    end

    private

    def send_create_user_broadcast(user_id)
      Success(Admin::CreateUserBroadcastJob.perform_later(user_id, request_id: Turbo.current_request_id))
    end
  end
end
