# frozen_string_literal: true

require "test_helper"

module Admin
  class CreateImportContractTest < ActiveSupport::TestCase
    setup do
      @contract = CreateImportContract.new
    end

    test "fails when spreadsheet is blank" do
      result = @contract.call(spreadsheet: "")

      assert_predicate result, :failure?
      assert_includes result.errors[:spreadsheet], I18n.t("contracts.errors.key?")
    end

    test "succeeds when a spreadsheet is uploaded" do
      result = @contract.call(spreadsheet: fixture_file_upload("users.csv", "text/csv"))

      assert_predicate result, :success?
      assert_empty result.errors
    end
  end
end
