# frozen_string_literal: true

require "application_system_test_case"

# The public area: signing in, signing up, asking for a password reset, and the
# rule that whoever is already signed in has no business on these pages.
class GuestTest < ApplicationSystemTestCase
  test "signing in with an unknown email shows an error" do
    visit new_session_path

    fill_in I18n.t("guest.sessions.new.email"), with: "nobody@example.com"
    fill_in I18n.t("guest.sessions.new.password"), with: "password"
    click_on I18n.t("guest.sessions.new.submit")

    assert_text I18n.t("contracts.errors.custom.authentication.invalid_credentials")
  end

  test "signing in with the wrong password shows an error" do
    user = create(:user)

    visit new_session_path

    fill_in I18n.t("guest.sessions.new.email"), with: user.email
    fill_in I18n.t("guest.sessions.new.password"), with: "wrong-password"
    click_on I18n.t("guest.sessions.new.submit")

    assert_text I18n.t("contracts.errors.custom.authentication.invalid_credentials")
  end

  test "registering with an email that is already taken shows an error" do
    taken = create(:user)

    visit new_registration_path
    fill_in_registration(email: taken.email)
    click_on I18n.t("guest.registrations.new.submit")

    assert_text I18n.t("errors.messages.taken")
  end

  test "registering with a mismatched password confirmation shows an error" do
    visit new_registration_path
    fill_in_registration(password_confirmation: "another-password")
    click_on I18n.t("guest.registrations.new.submit")

    assert_text I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
  end

  test "asking for a reset link confirms even for an email nobody uses" do
    visit new_password_path

    fill_in I18n.t("guest.passwords.new.email"), with: "nobody@example.com"
    click_on I18n.t("guest.passwords.new.submit")

    assert_text I18n.t("guest.passwords.create.success")
  end

  test "a signed-in admin has no access to the sign-in page" do
    sign_in_as create(:user, :admin)

    visit new_session_path

    assert_current_path admin_dashboard_path
  end

  test "a signed-in user has no access to the home page" do
    sign_in_as create(:user)

    visit root_path

    assert_current_path profile_path
  end

  test "a visitor creates an account and lands on their own profile" do
    visit root_path
    click_on I18n.t("guest.home.index.sign_up")

    fill_in_registration(full_name: "Marina Prado", email: "marina@example.com")
    click_on I18n.t("guest.registrations.new.submit")

    assert_text I18n.t("guest.registrations.create.success")
    assert_current_path profile_path
    assert_text "Marina Prado"
  end

  test "a visitor signs in and reaches the dashboard" do
    admin = create(:user, :admin)

    visit root_path
    click_on I18n.t("guest.home.index.sign_in")

    fill_in I18n.t("guest.sessions.new.email"), with: admin.email
    fill_in I18n.t("guest.sessions.new.password"), with: "password"
    click_on I18n.t("guest.sessions.new.submit")

    assert_text I18n.t("guest.sessions.create.success")
    assert_current_path admin_dashboard_path
    assert_text I18n.t("admin.dashboards.show.heading")
  end

  private

  # Every field is required and the passwords carry a minlength, so even the failure
  # cases have to fill the whole form to get past the browser's own validation.
  def fill_in_registration(full_name: "Marina Prado", email: "marina@example.com",
    password: "password123", password_confirmation: "password123")
    fill_in I18n.t("guest.registrations.new.full_name"), with: full_name
    fill_in I18n.t("guest.registrations.new.email"), with: email
    fill_in I18n.t("guest.registrations.new.password"), with: password
    fill_in I18n.t("guest.registrations.new.password_confirmation"), with: password_confirmation
  end
end
