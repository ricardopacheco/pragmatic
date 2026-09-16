# frozen_string_literal: true

require "test_helper"

module Admin
  class CreateImportOperationTest < ActiveSupport::TestCase
    setup do
      @operation = CreateImportOperation.new
      @admin = create(:user, :admin)
    end

    test "fails when the admin does not exist" do
      result = @operation.call(nil, spreadsheet: csv_upload)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.admin_not_found"), result.failure[:base]
    end

    test "fails when the user is not an admin" do
      result = @operation.call(create(:user).id, spreadsheet: csv_upload)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_is_not_admin"), result.failure[:base]
    end

    test "fails when the spreadsheet is missing" do
      result = @operation.call(@admin.id, {})

      assert_predicate result, :failure?
      assert_includes result.failure[:spreadsheet], I18n.t("contracts.errors.key?")
    end

    test "fails with the model errors when the file is not a spreadsheet" do
      result = @operation.call(@admin.id, spreadsheet: fixture_file_upload("avatar.png", "image/png"))

      assert_predicate result, :failure?
      assert_predicate result.failure[:spreadsheet], :present?
    end

    test "does not create the import when the operation fails" do
      assert_no_difference -> { Import.count } do
        @operation.call(@admin.id, {})
      end
    end

    test "succeeds and creates a queued import for the admin" do
      result = nil

      assert_difference -> { Import.count }, 1 do
        result = @operation.call(@admin.id, spreadsheet: csv_upload)
      end

      import = result.value!

      assert_predicate result, :success?
      assert_predicate import, :queued?
      assert_equal @admin, import.user
      assert_predicate import.spreadsheet, :attached?
    end

    private

    def csv_upload
      fixture_file_upload("users.csv", "text/csv")
    end
  end
end
