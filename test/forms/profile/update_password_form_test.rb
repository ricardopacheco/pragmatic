# frozen_string_literal: true

require "test_helper"

module Profile
  class UpdatePasswordFormTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, password: "password")
    end

    test "is named User, so form_with generates user fields" do
      assert_equal "user", UpdatePasswordForm.model_name.param_key
    end

    test "fails when attributes are blank" do
      form = UpdatePasswordForm.new

      assert_not form.submit(@user.id)
      assert_includes form.errors[:current_password], I18n.t("contracts.errors.key?")
      assert_includes form.errors[:password], I18n.t("contracts.errors.key?")
    end

    test "fails when the current password is wrong" do
      form = UpdatePasswordForm.new(valid_attributes.merge(current_password: "wrong-password"))

      assert_not form.submit(@user.id)
      assert_includes form.errors[:current_password], I18n.t("errors.messages.invalid")
    end

    test "fails when the confirmation does not match" do
      form = UpdatePasswordForm.new(valid_attributes.merge(password_confirmation: "different"))

      assert_not form.submit(@user.id)
      assert_includes form.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "does not change the password when it fails" do
      UpdatePasswordForm.new(valid_attributes.merge(current_password: "wrong-password")).submit(@user.id)

      assert @user.reload.authenticate("password")
    end

    test "succeeds and changes the password" do
      form = UpdatePasswordForm.new(valid_attributes)

      assert form.submit(@user.id)
      assert @user.reload.authenticate("new-password")
      assert_empty form.errors
    end

    private

    def valid_attributes
      {current_password: "password", password: "new-password", password_confirmation: "new-password"}
    end
  end
end
