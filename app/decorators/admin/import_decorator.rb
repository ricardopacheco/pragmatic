# frozen_string_literal: true

module Admin
  class ImportDecorator < Burgundy::Item
    BADGE_CLASSES = {
      "queued" => "badge-ghost",
      "processing" => "badge-soft badge-info",
      "completed" => "badge-soft badge-success",
      "completed_with_errors" => "badge-soft badge-warning",
      "failed" => "badge-soft badge-error"
    }.freeze

    attributes :id, :status, :total_rows, :succeeded_rows, :failed_rows, :processed_rows

    def filename
      return unless item.spreadsheet.attached?

      item.spreadsheet.filename.to_s
    end

    def status_label
      t("decorators.import.statuses.#{item.status}")
    end

    def status_badge_class
      BADGE_CLASSES.fetch(item.status, "badge-ghost")
    end

    def pending_rows
      [item.total_rows - processed_rows, 0].max
    end

    def progress_percentage
      total = item.total_rows
      return 0 if total.zero?

      ((processed_rows / total.to_f) * 100).round
    end

    def failures
      item.row_errors
    end

    def failures?
      item.row_errors.any?
    end

    def started_at
      format_time(item.started_at)
    end

    def finished_at
      format_time(item.finished_at)
    end

    def dom_id
      "import_#{item.id}"
    end

    private

    def format_time(time)
      return if time.blank?

      l(time, format: :short)
    end
  end
end
