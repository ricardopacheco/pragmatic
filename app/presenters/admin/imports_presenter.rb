# frozen_string_literal: true

module Admin
  class ImportsPresenter < ApplicationPresenter
    def render_imports
      return render_partial_path(partial: "admin/imports/empty") if imports.empty?

      render_partial_path(partial: "admin/imports/table", locals: {imports:})
    end

    def render_status_card
      case import.status
      when "failed" then render_partial_path(partial: "admin/imports/failure", locals: {import:})
      when "completed" then render_partial_path(partial: "admin/imports/completed", locals: {import:})
      else render_partial_path(partial: "admin/imports/progress", locals: {import:})
      end
    end

    def render_failures
      return unless import.failures?

      render_partial_path(partial: "admin/imports/failures", locals: {import:})
    end

    private

    def imports
      options.fetch(:imports, [])
    end

    def import
      options.fetch(:import)
    end
  end
end
