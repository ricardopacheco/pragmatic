# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin

    private

    def require_admin
      return if Current.user.admin?

      redirect_to profile_path, alert: t("admin.unauthorized")
    end
  end
end
