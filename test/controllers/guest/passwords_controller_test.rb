# frozen_string_literal: true

require "test_helper"

module Guest
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    setup { @user = create(:user, password: "password") }

    test "new renders the form" do
      get new_password_path

      assert_response :success
    end

    test "new redirects a signed-in user to their dashboard" do
      sign_in_as(@user)

      get new_password_path

      assert_redirected_to profile_path
    end

    test "create sends the reset email" do
      assert_enqueued_emails 1 do
        post passwords_path, params: {password: {email: @user.email}}
      end

      assert_redirected_to new_session_path
      assert_equal I18n.t("guest.passwords.create.success"), flash[:notice]
    end

    test "create says the same thing for an unknown email" do
      assert_no_enqueued_emails do
        post passwords_path, params: {password: {email: "notfound@example.com"}}
      end

      assert_redirected_to new_session_path
      assert_equal I18n.t("guest.passwords.create.success"), flash[:notice]
    end

    test "create rejects an invalid email" do
      post passwords_path, params: {password: {email: "invalid_email"}}

      assert_response :unprocessable_entity
    end

    # See the note in the sessions controller test: the null store never lets the
    # counter grow, so the threshold has to be simulated.
    test "create redirects with an alert once the rate limit is reached" do
      Rails.cache.stubs(:increment).returns(11)

      assert_no_enqueued_emails do
        post passwords_path, params: {password: {email: @user.email}}
      end

      assert_redirected_to new_password_path
      assert_equal I18n.t("guest.passwords.create.rate_limited"), flash[:alert]
    end

    test "edit renders the form" do
      get edit_password_path(@user.password_reset_token)

      assert_response :success
    end

    test "update changes the password" do
      patch password_path(@user.password_reset_token),
        params: {password: {password: "new-password", password_confirmation: "new-password"}}

      assert_redirected_to new_session_path
      assert_equal I18n.t("guest.passwords.update.success"), flash[:notice]
      assert @user.reload.authenticate("new-password")
    end

    test "update rejects an invalid token" do
      patch password_path("invalid-token"),
        params: {password: {password: "new-password", password_confirmation: "new-password"}}

      assert_response :unprocessable_entity
      assert @user.reload.authenticate("password")
    end

    test "update rejects a confirmation that does not match" do
      patch password_path(@user.password_reset_token),
        params: {password: {password: "new-password", password_confirmation: "different"}}

      assert_response :unprocessable_entity
      assert @user.reload.authenticate("password")
    end
  end
end
