# frozen_string_literal: true

module Admin
  class ProcessImportJob < ApplicationJob
    queue_as :default

    # No retry: importing again would create the users of the rows already read twice.
    rescue_from StandardError do |error|
      capture_exception(error)

      raise error
    end

    def perform(import_id)
      Admin::ProcessImportOperation.call(import_id)
    end
  end
end
