# frozen_string_literal: true

module Admin
  class CreateImportBroadcastJob < ApplicationJob
    queue_as :broadcast

    def perform(_import_id, request_id: nil)
      broadcast_latest_import
      broadcast_imports_list(request_id)
    end
  end
end
