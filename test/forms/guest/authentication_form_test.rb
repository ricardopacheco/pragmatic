# frozen_string_literal: true

require "test_helper"

module Guest
  class AuthenticationFormTest < ActiveSupport::TestCase
    test "is named Session, so form_with generates session fields" do
      assert_equal "session", AuthenticationForm.model_name.param_key
    end

    test "is never persisted" do
      assert_not_predicate AuthenticationForm.new, :persisted?
    end

    test "fails when attributes are blank and copies the field errors" do
      form = AuthenticationForm.new(email: "", password: "")

      assert_not form.submit
      # The form joins every message of a field into a single string (see ApplicationForm).
      assert_includes form.errors[:email].first, I18n.t("contracts.errors.key?")
      assert_includes form.errors[:password].first, I18n.t("contracts.errors.key?")
      assert_nil form.user
    end

    test "copies general errors to base" do
      form = AuthenticationForm.new(email: "notfound@example.com", password: "password")

      assert_not form.submit
      assert_includes form.errors[:base], I18n.t("contracts.errors.custom.authentication.invalid_credentials")
    end

    test "succeeds and exposes the authenticated user" do
      user = create(:user)
      form = AuthenticationForm.new(email: user.email, password: "password")

      assert form.submit
      assert_equal user, form.user
      assert_empty form.errors
    end

    test "sends the attributes to the operation" do
      Guest::AuthenticateOperation.expects(:call).with({"email" => "jane@example.com", "password" => "password"})

      AuthenticationForm.new(email: "jane@example.com", password: "password").submit
    end
  end
end
