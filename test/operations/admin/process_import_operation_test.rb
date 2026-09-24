# frozen_string_literal: true

require "test_helper"

module Admin
  class ProcessImportOperationTest < ActiveSupport::TestCase
    setup do
      @operation = ProcessImportOperation.new
    end

    test "fails when the import does not exist" do
      result = @operation.call(nil)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.admin.process_import.import_not_found"), result.failure[:base]
    end

    test "fails and marks the import as failed when the format is not supported" do
      import = create(:import)
      SpreadsheetReader.stubs(:for).returns(nil)

      result = @operation.call(import.id)

      assert_predicate result, :failure?
      assert_predicate import.reload, :failed?
      assert_equal I18n.t("operations.admin.process_import.unsupported_format"), import.failure_reason
    end

    test "fails and marks the import as failed when headers are missing" do
      import = create(:import, :missing_headers)

      result = @operation.call(import.id)

      assert_predicate result, :failure?
      assert_predicate import.reload, :failed?
      assert_equal(
        I18n.t("operations.admin.process_import.missing_headers", headers: "full_name, email"),
        import.failure_reason
      )
    end

    test "does not create users when the import fails" do
      import = create(:import, :missing_headers)

      assert_no_difference -> { User.count } do
        @operation.call(import.id)
      end
    end

    test "creates the valid rows and records the failed ones" do
      import = create(:import)

      assert_difference -> { User.count }, 2 do
        @operation.call(import.id)
      end

      import.reload

      assert_predicate import, :completed_with_errors?
      assert_equal 3, import.total_rows
      assert_equal 2, import.succeeded_rows
      assert_equal 1, import.failed_rows
      assert_predicate import.started_at, :present?
      assert_predicate import.finished_at, :present?
    end

    test "records the row number, the data and the messages of each failure" do
      import = create(:import)

      @operation.call(import.id)
      failure = import.reload.row_errors.sole

      assert_equal 4, failure["row"]
      assert_equal "not-an-email", failure["data"]["email"]
      assert_includes failure["messages"], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "creates the users with the role of the spreadsheet" do
      import = create(:import)

      @operation.call(import.id)

      assert_predicate User.find_by(email: "joao@example.com"), :profile?
      assert_predicate User.find_by(email: "maria@example.com"), :admin?
    end

    test "completes without errors when every row is valid" do
      import = create(:import, :xlsx)
      result = nil

      assert_difference -> { User.count }, 2 do
        result = @operation.call(import.id)
      end

      assert_predicate result, :success?
      assert_predicate import.reload, :completed?
      assert_equal 2, import.succeeded_rows
      assert_equal 0, import.failed_rows
      assert_empty import.row_errors
    end

    test "fails and marks the import as failed when the file cannot be read" do
      import = create(:import, :malformed)

      result = @operation.call(import.id)

      assert_predicate result, :failure?
      assert_predicate import.reload, :failed?
      assert_equal I18n.t("operations.admin.process_import.unreadable_file"), import.failure_reason
    end

    test "marks the import as failed and raises again on an unexpected error" do
      import = create(:import)
      SpreadsheetReader::Csv.any_instance.stubs(:each_row).raises(ActiveRecord::ConnectionNotEstablished)

      assert_raises(ActiveRecord::ConnectionNotEstablished) { @operation.call(import.id) }

      assert_predicate import.reload, :failed?
      assert_equal I18n.t("operations.admin.process_import.unexpected_error"), import.failure_reason
    end

    test "records the errors of the user that failed to save" do
      import = create(:import, :xlsx)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:email, :taken)
      User.any_instance.stubs(:save).returns(false)
      User.any_instance.stubs(:errors).returns(errors)

      assert_no_difference -> { User.count } do
        @operation.call(import.id)
      end

      import.reload

      assert_equal 2, import.failed_rows
      assert_equal errors.full_messages, import.row_errors.first["messages"]
    end

    test "saves the progress before reaching the end of a long spreadsheet" do
      import = create(:import, :batch)

      # Start and finish always broadcast; the third one is the mid-file save.
      assert_enqueued_jobs 3, only: Admin::ImportProgressBroadcastJob do
        @operation.call(import.id)
      end

      assert_equal ProcessImportOperation::BATCH_SIZE, import.reload.succeeded_rows
    end

    test "enqueues the progress broadcast job" do
      import = create(:import)

      assert_enqueued_with(job: Admin::ImportProgressBroadcastJob, queue: "broadcast") do
        @operation.call(import.id)
      end
    end
  end
end
