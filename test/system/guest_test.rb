# frozen_string_literal: true

require "application_system_test_case"

class GuestTest < ApplicationSystemTestCase
  setup { @user = create(:user, password: "password") }

  test "signing in with valid credentials lands on the profile" do
    visit new_session_path

    fill_in "Email", with: @user.email
    fill_in "Password", with: "password"
    click_on "Sign in"

    assert_current_path profile_path
    assert_selector "h1", text: @user.full_name
  end

  # Turbo renders the 422 response in place without touching the URL,
  # so the browser stays on /session/new even though the form posted to /session.
  test "signing in with a wrong password keeps the form with an error" do
    visit new_session_path

    fill_in "Email", with: @user.email
    fill_in "Password", with: "wrong-password"
    click_on "Sign in"

    assert_current_path new_session_path
    assert_selector "[role=alert].alert-error"
    assert_field "Email", with: @user.email
  end
end
