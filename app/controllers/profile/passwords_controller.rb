# frozen_string_literal: true

module Profile
  class PasswordsController < BaseController
    def update
      @password_form = UpdatePasswordForm.new(password_params)

      if @password_form.submit(Current.user.id)
        redirect_to profile_path, notice: t(".success")
      else
        @form = UpdateProfileForm.new(user: Current.user)

        render "profile/profiles/edit", status: :unprocessable_content
      end
    end

    private

    def password_params
      params.expect(user: %i[current_password password password_confirmation])
    end
  end
end
