# frozen_string_literal: true

module Admin
  class ImportProgressBroadcastJob < ApplicationJob
    queue_as :broadcast

    # Runs from the import job, so there is no request to skip.
    def perform(import_id)
      broadcast_import(import_id)
      broadcast_imports_list
      broadcast_latest_import
      broadcast_dashboard
    end
  end
end
