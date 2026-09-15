# frozen_string_literal: true

require "test_helper"

module Profile
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = create(:user, full_name: "Jane Cooper", email: "jane@example.com", password: "password")
    end

    test "show requires an authenticated user" do
      get profile_path

      assert_redirected_to new_session_path
    end

    test "show renders the profile with the active sessions" do
      sign_in_as(@user)

      get profile_path

      assert_response :success
      assert_select "#sessions li", 1
    end

    test "edit renders both forms" do
      sign_in_as(@user)

      get edit_profile_path

      assert_response :success
    end

    test "update changes the profile" do
      sign_in_as(@user)

      patch profile_path, params: {user: {full_name: "Jane C.", email: "jane.c@example.com"}}

      assert_redirected_to profile_path
      assert_equal I18n.t("profile.profiles.update.success"), flash[:notice]
      assert_equal "Jane C.", @user.reload.full_name
    end

    test "update rejects an email that belongs to another user" do
      create(:user, email: "taken@example.com")
      sign_in_as(@user)

      patch profile_path, params: {user: {full_name: "Jane Cooper", email: "taken@example.com"}}

      assert_response :unprocessable_entity
      assert_equal "jane@example.com", @user.reload.email
    end
  end
end
