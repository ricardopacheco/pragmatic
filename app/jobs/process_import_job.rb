# frozen_string_literal: true

module Admin
  class ProcessImportJob < ApplicationJob
    queue_as :default

    def perform(import_id)
      Admin::ProcessImportOperation.call(import_id)
    end
  end
end
