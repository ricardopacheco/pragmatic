# frozen_string_literal: true

module Admin
  class UpdateUserOperation < ApplicationOperation
    def call(admin_id, user_id, attributes)
      yield find_and_validate_user_admin(admin_id)
      user = yield find_user(user_id)
      validated = yield validate_contract(Admin::UpdateUserContract, attributes, user:)

      ActiveRecord::Base.transaction do
        yield update_user_on_database(user, user_attributes(validated))
        yield remove_avatar_image(user, validated)
        yield send_update_user_broadcast(user.id)
      end

      Success(user)
    end

    private

    def user_attributes(validated)
      validated.to_h.except(:remove_avatar_image)
    end

    def send_update_user_broadcast(user_id)
      Success(Admin::UpdateUserBroadcastJob.perform_later(user_id, request_id: Turbo.current_request_id))
    end
  end
end
