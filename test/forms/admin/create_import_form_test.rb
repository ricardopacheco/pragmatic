# frozen_string_literal: true

require "test_helper"

module Admin
  class CreateImportFormTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
    end

    test "is named Import, so form_with generates import fields" do
      assert_equal "import", CreateImportForm.model_name.param_key
    end

    test "fails when the spreadsheet is missing" do
      form = CreateImportForm.new

      assert_not form.submit(@admin.id)
      assert_includes form.errors[:spreadsheet], I18n.t("contracts.errors.key?")
      assert_nil form.import
    end

    test "fails when the file is not a spreadsheet" do
      form = CreateImportForm.new(spreadsheet: fixture_file_upload("avatar.png", "image/png"))

      assert_not form.submit(@admin.id)
      assert_predicate form.errors[:spreadsheet], :present?
    end

    test "copies operation errors to base when the admin is not found" do
      form = CreateImportForm.new(spreadsheet: csv_upload)

      assert_not form.submit(nil)
      assert_includes form.errors[:base], I18n.t("operations.base.admin_not_found")
    end

    test "succeeds, creates the import and enqueues the processing" do
      form = CreateImportForm.new(spreadsheet: csv_upload)
      submitted = nil

      assert_enqueued_with(job: Admin::ProcessImportJob) do
        submitted = form.submit(@admin.id)
      end

      assert submitted
      assert_predicate form.import, :queued?
      assert_equal @admin, form.import.user
    end

    private

    def csv_upload
      fixture_file_upload("users.csv", "text/csv")
    end
  end
end
