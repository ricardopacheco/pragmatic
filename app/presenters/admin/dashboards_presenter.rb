# frozen_string_literal: true

module Admin
  class DashboardsPresenter < ApplicationPresenter
    def render_latest_import
      return render_partial_path(partial: "admin/dashboards/no_imports") if latest_import.blank?

      render_partial_path(partial: "admin/dashboards/latest_import", locals: {import: latest_import})
    end

    private

    def latest_import
      options[:latest_import]
    end
  end
end
