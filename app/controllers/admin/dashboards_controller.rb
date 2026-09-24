# frozen_string_literal: true

module Admin
  class DashboardsController < BaseController
    def show
      @dashboard = DashboardDecorator.new
      @recent_users = UserDecorator.wrap(User.recent)
      @latest_import = latest_import
      @presenter = presenter_class.new(view_context, latest_import: @latest_import)
    end

    private

    def latest_import
      import = Import.latest.first

      ImportDecorator.new(import) if import
    end
  end
end
