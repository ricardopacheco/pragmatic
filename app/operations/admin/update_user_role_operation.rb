# frozen_string_literal: true

module Admin
  class UpdateUserRoleOperation < ApplicationOperation
    def call(admin_id, user_id, attributes)
      yield find_and_validate_user_admin(admin_id)
      user = yield find_user(user_id)
      validated = yield validate_contract(Admin::UpdateUserRoleContract, attributes)

      ActiveRecord::Base.transaction do
        yield update_user_on_database(user, role: validated[:role])
        yield send_update_user_role_broadcast(user.id)
      end

      Success(user)
    end

    private

    def send_update_user_role_broadcast(user_id)
      Success(Admin::UpdateUserRoleBroadcastJob.perform_later(user_id, request_id: Turbo.current_request_id))
    end
  end
end
