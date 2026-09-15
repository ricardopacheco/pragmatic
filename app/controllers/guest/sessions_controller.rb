# frozen_string_literal: true

module Guest
  class SessionsController < BaseController
    skip_before_action :redirect_signed_in_user, only: :destroy
    before_action :require_authentication, only: :destroy

    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to new_session_path, alert: t("guest.sessions.create.rate_limited") }

    def new
      @form = AuthenticationForm.new
    end

    def create
      @form = AuthenticationForm.new(session_params)

      if @form.submit
        start_new_session_for(@form.user)
        redirect_to after_authentication_url, notice: t(".success")
      else
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      terminate_session

      redirect_to new_session_path, notice: t(".success")
    end

    private

    def session_params
      params.expect(session: %i[email password])
    end
  end
end
