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
  end
end
