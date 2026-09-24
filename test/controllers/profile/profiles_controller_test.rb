# frozen_string_literal: true

require "test_helper"

module Profile
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = create(:user)
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

    test "show renders the profile of an admin too" do
      admin = create(:user, :admin)
      sign_in_as(admin)

      get profile_path

      assert_response :success
      assert_select "h1", text: admin.full_name
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

      assert_no_changes -> { @user.reload.email } do
        patch profile_path, params: {user: {full_name: "Jane C.", email: "taken@example.com"}}
      end

      assert_response :unprocessable_entity
    end

    test "destroy deletes the account and signs the user out" do
      sign_in_as(@user)

      assert_difference -> { User.count }, -1 do
        delete profile_path
      end

      assert_redirected_to root_path
      assert_equal I18n.t("profile.profiles.destroy.success"), flash[:notice]
      assert_predicate cookies[:session_id], :blank?
    end

    test "destroy keeps the user signed in and shows the error when it fails" do
      sign_in_as(@user)
      User.any_instance.stubs(:destroy).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:base, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      assert_no_difference -> { User.count } do
        delete profile_path
      end

      assert_redirected_to profile_path
      assert_equal I18n.t("errors.messages.invalid"), flash[:alert]
    end
  end
end
