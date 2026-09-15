# frozen_string_literal: true

require "application_system_test_case"

# The signed-in user's own account: reading it, editing it, changing the password
# and deleting it.
class ProfileTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, full_name: "Marina Prado")
  end

  test "saving a name shorter than the minimum shows an error" do
    length = Rails.configuration.x.validations.full_name_length

    sign_in_as @user
    visit edit_profile_path

    fill_in I18n.t("profile.profiles.edit.full_name"), with: "A"
    click_on I18n.t("profile.profiles.edit.save")

    assert_text I18n.t("contracts.errors.custom.macro.full_name_format", min: length.min, max: length.max)
  end

  test "saving an email that belongs to someone else shows an error" do
    taken = create(:user)

    sign_in_as @user
    visit edit_profile_path

    fill_in I18n.t("profile.profiles.edit.email"), with: taken.email
    click_on I18n.t("profile.profiles.edit.save")

    assert_text I18n.t("errors.messages.taken")
  end

  test "the user edits name and email" do
    sign_in_as @user
    click_on I18n.t("profile.profiles.show.edit")

    fill_in I18n.t("profile.profiles.edit.full_name"), with: "Marina do Prado"
    fill_in I18n.t("profile.profiles.edit.email"), with: "marina.prado@example.com"
    click_on I18n.t("profile.profiles.edit.save")

    assert_text I18n.t("profile.profiles.update.success")
    assert_current_path profile_path
    assert_text "Marina do Prado"
    assert_text "marina.prado@example.com"
  end

  test "changing the password with the wrong current one shows an error" do
    sign_in_as @user
    visit edit_profile_path

    fill_in_password(current_password: "wrong-password")
    click_on I18n.t("profile.profiles.edit.update_password")

    assert_text I18n.t("errors.messages.invalid")
  end

  test "changing the password with a mismatched confirmation shows an error" do
    sign_in_as @user
    visit edit_profile_path

    fill_in_password(password_confirmation: "another-password")
    click_on I18n.t("profile.profiles.edit.update_password")

    assert_text I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
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

  test "the new password is the one that works on the next sign in" do
    sign_in_as @user
    visit edit_profile_path

    fill_in_password
    click_on I18n.t("profile.profiles.edit.update_password")
    assert_text I18n.t("profile.passwords.update.success")

    sign_out
    sign_in_as @user, password: "brand-new-password"

    assert_current_path profile_path
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
