# frozen_string_literal: true

require "application_system_test_case"

# The signed-in user's own account: reading it, editing it, changing the password
# and deleting it.
class ProfileTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, full_name: "Marina Prado")
  end

  test "the profile shows the account details and the active session" do
    sign_in_as @user

    assert_current_path profile_path
    assert_text @user.full_name
    assert_text @user.email
    assert_text I18n.t("profile.profiles.show.sessions.title")
  end

  test "the user signs out from the account menu" do
    sign_in_as @user

    sign_out

    assert_text I18n.t("guest.sessions.destroy.success")
    assert_current_path new_session_path
  end

  private

  def fill_in_password(current_password: "password", password: "brand-new-password",
    password_confirmation: "brand-new-password")
    fill_in I18n.t("profile.profiles.edit.current_password"), with: current_password
    fill_in I18n.t("profile.profiles.edit.new_password"), with: password
    fill_in I18n.t("profile.profiles.edit.confirm_password"), with: password_confirmation
  end

  # The menu is a daisyUI dropdown: its contents only show once the trigger has focus.
  def sign_out
    find("[aria-label='#{I18n.t("layouts.profile.account_menu")}']").click
    click_on I18n.t("layouts.profile.sign_out")
  end
end
