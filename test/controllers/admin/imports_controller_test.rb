# frozen_string_literal: true

require "test_helper"

module Admin
  class ImportsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in_as(@admin)
    end

    test "rejects a regular user" do
      sign_out
      sign_in_as(create(:user))

      get admin_imports_path

      assert_redirected_to profile_path
    end

    test "index shows the empty state when there is no import" do
      get admin_imports_path

      assert_response :success
      assert_select "h3", text: I18n.t("admin.imports.empty.heading")
    end

    test "index lists the imports" do
      create(:import, user: @admin)

      get admin_imports_path

      assert_response :success
      assert_select "#imports tr", 1
    end

    test "create starts an import and enqueues the processing" do
      assert_enqueued_with(job: Admin::ProcessImportJob) do
        assert_difference -> { Import.count }, 1 do
          post admin_imports_path, params: {import: {spreadsheet: fixture_file_upload("users.csv", "text/csv")}}
        end
      end

      assert_redirected_to admin_import_path(Import.last)
      assert_equal I18n.t("admin.imports.create.success"), flash[:notice]
    end

    test "create rejects a file that is not a spreadsheet" do
      assert_no_difference -> { Import.count } do
        post admin_imports_path, params: {import: {spreadsheet: fixture_file_upload("avatar.png", "image/png")}}
      end

      assert_response :unprocessable_entity
    end

    test "show renders the progress of a running import" do
      import = create(:import, user: @admin, status: :processing, total_rows: 10, succeeded_rows: 4)

      get admin_import_path(import)

      assert_response :success
      assert_select "##{import.id}_progress", false
      assert_select "#import_#{import.id}_progress"
    end

    test "show renders the failure card and no failed rows table" do
      import = create(:import, user: @admin, status: :failed, failure_reason: "Unsupported file format")

      get admin_import_path(import)

      assert_response :success
      assert_select "#import_#{import.id}_progress", text: /Unsupported file format/
      assert_select "#import_#{import.id}_failures", false
    end

    test "show renders the failed rows when there are any" do
      import = create(
        :import,
        user: @admin,
        status: :completed_with_errors,
        total_rows: 2,
        succeeded_rows: 1,
        failed_rows: 1,
        row_errors: [{"row" => 3, "data" => {"email" => "nope"}, "messages" => ["Email is invalid"]}]
      )

      get admin_import_path(import)

      assert_response :success
      assert_select "#import_#{import.id}_failures tr", 1
    end
  end
end
