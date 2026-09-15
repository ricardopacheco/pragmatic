# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Chrome by default; SYSTEM_TEST_BROWSER=headless_firefox runs the same suite against Firefox,
  # which is how CI covers both. Rails maps either name to the right Selenium options.
  #
  # Deliberately not BROWSER: desktop Linux already uses that name for the user's preferred
  # browser, and picking it up turned every test into "unknown driver: :omarchy-launch-browser".
  BROWSER = ENV.fetch("SYSTEM_TEST_BROWSER", "headless_chrome").to_sym

  driven_by :selenium, using: BROWSER, screen_size: [1400, 1400] do |options|
    # Chromium's sandbox needs the SUID helper from Debian's chromium-sandbox package, which
    # --no-install-recommends leaves out of the test image, and rootless Docker would fight it even
    # if it were there. Without this the browser exits at startup: "Chrome instance exited".
    # Only the container sets the variable, so a local run keeps its sandbox.
    options.add_argument("--no-sandbox") if BROWSER == :headless_chrome && ENV["SYSTEM_TEST_CHROME_NO_SANDBOX"]
  end

  # A browser per worker is expensive, so these run less parallel than the rest.
  parallelize(workers: 4)

  # Labels are matched exactly: the forms pair "Password" with "Confirm password",
  # and Capybara's default substring match would find both.
  Capybara.exact = true

  # The users list names its search, row actions and role toggle with aria-label,
  # which is also how the tests should reach them.
  Capybara.enable_aria_label = true

  private

  # perform_enqueued_jobs walks the queue as it stood when called, so a job enqueued
  # by another job never runs — the import broadcasts its progress from inside the
  # job that processes it. Repeating until the queue empties covers those.
  def perform_all_enqueued_jobs
    perform_enqueued_jobs while enqueued_jobs.any?
  end

  # Filling the form is the only way a real browser gets a session cookie, so every
  # signed-in scenario starts here.
  def sign_in_as(user, password: "password")
    visit new_session_path

    fill_in I18n.t("guest.sessions.new.email"), with: user.email
    fill_in I18n.t("guest.sessions.new.password"), with: password
    click_on I18n.t("guest.sessions.new.submit")

    # Waits for the redirect to land, so a test that navigates right after signing
    # in does not race the visit it is about to make.
    assert_text I18n.t("guest.sessions.create.success")

    user
  end
end
