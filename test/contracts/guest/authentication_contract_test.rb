# frozen_string_literal: true

require "test_helper"

module Guest
  class AuthenticationContractTest < ActiveSupport::TestCase
    setup do
      @contract = AuthenticationContract.new
    end

    test "fails when attributes are blank" do
      result = @contract.call(email: "", password: "")

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.key?")
      assert_includes result.errors[:password], I18n.t("contracts.errors.key?")
    end

    test "fails when email has an invalid format" do
      result = @contract.call(email: "invalid_email", password: "password")

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "fails when email is not registered" do
      result = @contract.call(email: "notfound@example.com", password: "password")

      assert_predicate result, :failure?
      assert_includes result.errors[nil], I18n.t("contracts.errors.custom.authentication.invalid_credentials")
    end

    test "fails when password is wrong" do
      user = create(:user)
      result = @contract.call(email: user.email, password: "wrong-password")

      assert_predicate result, :failure?
      assert_includes result.errors[nil], I18n.t("contracts.errors.custom.authentication.invalid_credentials")
    end

    test "succeeds when credentials are valid" do
      user = create(:user)
      result = @contract.call(email: user.email.upcase, password: "password")

      assert_predicate result, :success?
      assert_empty result.errors
      assert_equal user, result.context[:user]
    end
  end
end
