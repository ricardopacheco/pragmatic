# frozen_string_literal: true

require "test_helper"

module Guest
  class RequestPasswordResetContractTest < ActiveSupport::TestCase
    setup do
      @contract = RequestPasswordResetContract.new
    end

    test "fails when email is blank" do
      result = @contract.call(email: "")

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.key?")
    end

    test "fails when email has an invalid format" do
      result = @contract.call(email: "invalid_email")

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "succeeds even when email is not registered" do
      result = @contract.call(email: "notfound@example.com")

      assert_predicate result, :success?
      assert_empty result.errors
    end
  end
end
