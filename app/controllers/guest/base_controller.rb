# frozen_string_literal: true

module Guest
  # Public context: no authentication required, and no place for who is already
  # signed in.
  class BaseController < ApplicationController
    allow_unauthenticated_access
    layout "guest"

    before_action :redirect_signed_in_user

    private

    def redirect_signed_in_user
      return unless authenticated?

      redirect_to dashboard_path_for(Current.user)
    end
  end
end
