# frozen_string_literal: true

module Admin
  class UpdateUserRoleOperation < ApplicationOperation
    def call(admin_id, user_id, attributes)
      yield find_and_validate_user_admin(admin_id)
      user = yield find_user(user_id)
      validated = yield validate_contract(Admin::UpdateUserRoleContract, attributes)

      ActiveRecord::Base.transaction do
        yield update_user_on_database(user, role: validated[:role])
      end

      Success(user)
    end
  end
end
