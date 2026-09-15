# frozen_string_literal: true

module Admin
  class DashboardsController < BaseController
    RECENT_USERS = 4

    def show
      @dashboard = DashboardDecorator.new(Current.user)
      @recent_users = UserDecorator.wrap(User.order(created_at: :desc).limit(RECENT_USERS))
      @latest_import = latest_import
      @presenter = presenter_class.new(view_context, Current.user, latest_import: @latest_import)
    end

    private

    def latest_import
      import = Import.latest.first

      ImportDecorator.new(import) if import
    end
  end
end
