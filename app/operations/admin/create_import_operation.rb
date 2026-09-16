# frozen_string_literal: true

module Admin
  class CreateImportOperation < ApplicationOperation
    def call(admin_id, attributes)
      admin = yield find_and_validate_user_admin(admin_id)
      validated = yield validate_contract(Admin::CreateImportContract, attributes)

      ActiveRecord::Base.transaction do
        @import = yield create_import_on_database(admin, validated[:spreadsheet])
        yield enqueue_processing(@import)
      end

      Success(@import)
    end

    private

    def create_import_on_database(admin, spreadsheet)
      import = admin.imports.new(spreadsheet:)

      return Success(import) if import.save

      Failure(import.errors.to_hash)
    end

    def enqueue_processing(import)
      Success(Admin::ProcessImportJob.perform_later(import.id))
    end
  end
end
