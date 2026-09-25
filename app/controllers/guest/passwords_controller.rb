# frozen_string_literal: true

module Guest
  class PasswordsController < BaseController
    rate_limit to: 10, within: 3.minutes, only: %i[create update],
      with: -> { redirect_to new_password_path, alert: t("guest.passwords.#{action_name}.rate_limited") }

    def new
      @form = RequestPasswordResetForm.new
    end

    def create
      @form = RequestPasswordResetForm.new(email_params)

      if @form.submit
        redirect_to new_session_path, notice: t(".success")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @form = ResetPasswordForm.new(token: params[:token])
    end

    def update
      @form = ResetPasswordForm.new(password_params.merge(token: params[:token]))

      if @form.submit
        redirect_to new_session_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def email_params
      params.expect(password: [:email])
    end

    def password_params
      params.expect(password: %i[password password_confirmation])
    end
  end
end
