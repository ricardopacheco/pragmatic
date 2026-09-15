# frozen_string_literal: true

require "test_helper"

module Guest
  class AuthenticateOperationTest < ActiveSupport::TestCase
    setup do
      @operation = AuthenticateOperation.new
    end

    test "fails when attributes are blank" do
      result = @operation.call({})

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:password], I18n.t("contracts.errors.key?")
    end

    test "fails when the email is not registered" do
      result = @operation.call(email: "notfound@example.com", password: "password")

      assert_predicate result, :failure?
      assert_includes result.failure[nil], I18n.t("contracts.errors.custom.authentication.invalid_credentials")
    end

    test "fails when the password is wrong" do
      user = create(:user)
      result = @operation.call(email: user.email, password: "wrong-password")

      assert_predicate result, :failure?
      assert_includes result.failure[nil], I18n.t("contracts.errors.custom.authentication.invalid_credentials")
    end

    test "succeeds and returns the authenticated user" do
      user = create(:user)
      result = @operation.call(email: user.email.upcase, password: "password")

      assert_predicate result, :success?
      assert_equal user, result.value!
    end
  end
end
