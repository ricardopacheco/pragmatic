# frozen_string_literal: true

require "test_helper"

module Profile
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = create(:user, password: "password")
      sign_in_as(@user)
    end

    test "update changes the password" do
      patch profile_password_path, params: {user: valid_attributes}

      assert_redirected_to profile_path
      assert_equal I18n.t("profile.passwords.update.success"), flash[:notice]
      assert @user.reload.authenticate("new-password")
    end

    test "update rejects a wrong current password" do
      patch profile_password_path, params: {user: valid_attributes.merge(current_password: "wrong-password")}

      assert_response :unprocessable_entity
      assert @user.reload.authenticate("password")
    end

    test "update rejects a confirmation that does not match" do
      patch profile_password_path, params: {user: valid_attributes.merge(password_confirmation: "different")}

      assert_response :unprocessable_entity
      assert @user.reload.authenticate("password")
    end

    test "update requires an authenticated user" do
      sign_out

      patch profile_password_path, params: {user: valid_attributes}

      assert_redirected_to new_session_path
    end

    private

    def valid_attributes
      {current_password: "password", password: "new-password", password_confirmation: "new-password"}
    end
  end
end
