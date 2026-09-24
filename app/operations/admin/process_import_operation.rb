# frozen_string_literal: true

module Admin
  # Runs in the background (Admin::ProcessImportJob). Reads the spreadsheet row by
  # row, creates the users and keeps counters, failures and status up to date.
  class ProcessImportOperation < ApplicationOperation
    I18N_SCOPE = "operations.admin.process_import"
    BATCH_SIZE = 50

    def call(import_id)
      import = yield find_import(import_id)
      reader_class = yield reader_class_for(import)

      process(import, reader_class)
    rescue SpreadsheetReader::MissingHeadersError => error
      fail_import(import, I18n.t("#{I18N_SCOPE}.missing_headers", headers: error.message))
    rescue SpreadsheetReader::Error, ::CSV::MalformedCSVError
      fail_import(import, I18n.t("#{I18N_SCOPE}.unreadable_file"))
    rescue Dry::Monads::Do::Halt
      # How `yield` returns a Failure early: it must not be taken for an unexpected error.
      raise
    rescue => error
      fail_import(import, I18n.t("#{I18N_SCOPE}.unexpected_error")) if import
      raise error
    end

    private

    def find_import(import_id)
      import = Import.find_by(id: import_id)

      return Failure(base: I18n.t("#{I18N_SCOPE}.import_not_found")) if import.blank?

      Success(import)
    end

    def reader_class_for(import)
      reader_class = SpreadsheetReader.for(import.spreadsheet.content_type)

      return Success(reader_class) if reader_class

      fail_import(import, I18n.t("#{I18N_SCOPE}.unsupported_format"))
    end

    def process(import, reader_class)
      import.spreadsheet.open do |file|
        reader = reader_class.new(file.path)

        start(import, reader.total_rows)
        import_rows(import, reader)
      end

      finish(import)

      Success(import)
    end

    def start(import, total_rows)
      import.update!(status: :processing, total_rows:, started_at: Time.current)
      broadcast_progress(import)
    end

    def import_rows(import, reader)
      reader.each_row do |row_number, attributes|
        import_row(import, row_number, attributes)

        save_progress(import) if import.processed_rows % BATCH_SIZE == 0
      end
    end

    def import_row(import, row_number, attributes)
      result = Admin::CreateUserContract.new.call(user_attributes(attributes))
      user = User.new(result.to_h) if result.success?

      if user&.save
        import.succeeded_rows += 1
      else
        import.failed_rows += 1
        import.row_errors << row_error(row_number, attributes, failure_messages(result, user))
      end
    end

    # Imported users get a random password: the spreadsheet has no password column,
    # so they sign in after using "forgot password".
    def user_attributes(attributes)
      password = SecureRandom.hex(20)

      attributes.merge(
        role: attributes[:role].presence&.downcase || "profile",
        password:,
        password_confirmation: password
      )
    end

    # The contract mirrors the model validations, so the model only fails a row the
    # contract accepted for a reason it could not see, like a uniqueness race.
    def failure_messages(result, user)
      return result.errors.to_h.values.flatten if result.failure?

      user.errors.full_messages
    end

    def row_error(row_number, attributes, messages)
      {"row" => row_number, "data" => attributes.stringify_keys, "messages" => messages}
    end

    def save_progress(import)
      import.save!
      broadcast_progress(import)
    end

    def finish(import)
      import.finish!
      broadcast_progress(import)
    end

    def fail_import(import, reason)
      import.update!(status: :failed, failure_reason: reason, finished_at: Time.current)
      broadcast_progress(import)

      Failure(base: reason)
    end

    def broadcast_progress(import)
      Admin::ImportProgressBroadcastJob.perform_later(import.id)
    end
  end
end
