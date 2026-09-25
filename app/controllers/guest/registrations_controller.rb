# frozen_string_literal: true

module Guest
  class RegistrationsController < BaseController
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to new_registration_path, alert: t("guest.registrations.create.rate_limited") }

    def new
      @form = RegistrationForm.new
    end

    def create
      @form = RegistrationForm.new(registration_params)

      if @form.submit
        start_new_session_for(@form.user)
        redirect_to profile_path, notice: t(".success")
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def registration_params
      params.expect(user: %i[full_name email password password_confirmation avatar_image])
    end
  end
end
