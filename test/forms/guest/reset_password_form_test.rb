# frozen_string_literal: true

require "test_helper"

module Guest
  class ResetPasswordFormTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, password: "password")
    end

    test "fails when attributes are blank" do
      form = ResetPasswordForm.new

      assert_not form.submit
      assert_includes form.errors[:token].first, I18n.t("contracts.errors.key?")
      assert_includes form.errors[:password].first, I18n.t("contracts.errors.key?")
    end

    test "copies the invalid token error to base" do
      form = ResetPasswordForm.new(valid_attributes.merge(token: "invalid-token"))

      assert_not form.submit
      assert_includes form.errors[:base], I18n.t("contracts.errors.custom.password_reset.invalid_token")
    end

    test "fails when the confirmation does not match" do
      form = ResetPasswordForm.new(valid_attributes.merge(password_confirmation: "different"))

      assert_not form.submit
      assert_includes form.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "succeeds, changes the password and exposes the user" do
      form = ResetPasswordForm.new(valid_attributes)

      assert form.submit
      assert_equal @user, form.user
      assert @user.reload.authenticate("new-password")
    end

    private

    def valid_attributes
      {token: @user.password_reset_token, password: "new-password", password_confirmation: "new-password"}
    end
  end
end
