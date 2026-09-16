# frozen_string_literal: true

require "application_system_test_case"

# Importing users from a spreadsheet. The rows are processed in a background job,
# so each test uploads the file and then runs the queue before checking the result,
# which the open page receives without being reloaded.
class AdminImportsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin)
  end

  test "a spreadsheet without the required headers is reported as failed" do
    sign_in_as @admin

    upload("users_missing_headers.csv")
    perform_all_enqueued_jobs

    assert_text I18n.t("decorators.import.statuses.failed")
    assert_text I18n.t("admin.imports.failure.heading")
  end

  test "the valid rows are imported and the invalid ones are listed" do
    sign_in_as @admin

    upload("users.csv")
    perform_all_enqueued_jobs

    # The fixture carries two usable rows and one with a malformed email.
    assert_text I18n.t("decorators.import.statuses.completed_with_errors")
    assert_text "not-an-email"

    assert User.exists?(email: "joao@example.com")
    assert User.exists?(email: "maria@example.com")
  end

  test "the import shows up in the list of recent imports" do
    sign_in_as @admin

    upload("users.csv")
    perform_all_enqueued_jobs

    visit admin_imports_path

    assert_text "users.csv"
    assert_text I18n.t("decorators.import.statuses.completed_with_errors")
  end

  private

  def upload(filename)
    visit admin_imports_path

    attach_file I18n.t("admin.imports.form.spreadsheet"), file_fixture(filename)
    click_on I18n.t("admin.imports.form.submit")

    assert_text I18n.t("admin.imports.create.success")
  end
end
