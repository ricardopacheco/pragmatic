# frozen_string_literal: true

module Admin
  class RolesController < BaseController
    def update
      @form = UpdateUserRoleForm.new(role_params)

      if @form.submit(Current.user.id, params[:user_id])
        redirect_to admin_users_path, notice: t(".success", name: @form.user.full_name)
      else
        redirect_to admin_users_path, alert: @form.errors.full_messages.to_sentence
      end
    end

    private

    def role_params
      params.expect(user: [:role])
    end
  end
end
