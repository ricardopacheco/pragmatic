# frozen_string_literal: true

require "application_system_test_case"

# Real time: what one admin does has to reach another admin's screen without a
# reload. Both browsers and the server live in this same process during a system
# test, and the test cable adapter extends the async one, so the broadcasts really
# are delivered here.
class RealtimeTest < ApplicationSystemTestCase
  test "a user deleted by one admin leaves the other admin's list on its own" do
    doomed = create(:user)

    using_session(:watcher) do
      sign_in_as create(:user, :admin)
      visit admin_users_path

      assert_text doomed.full_name
    end

    sign_in_as create(:user, :admin)
    visit admin_users_path

    wait_for_stimulus("dialog")
    click_on I18n.t("admin.users.user.delete", name: doomed.full_name)
    click_on I18n.t("admin.users.delete_modal.confirm")
    assert_text I18n.t("admin.users.destroy.success")

    perform_all_enqueued_jobs

    using_session(:watcher) do
      assert_no_text doomed.full_name
    end
  end

  test "a user created by one admin shows up on the other admin's list" do
    using_session(:watcher) do
      sign_in_as create(:user, :admin)
      visit admin_users_path

      assert_no_text "Carla Nunes"
    end

    sign_in_as create(:user, :admin)
    create_user_through_the_form

    perform_all_enqueued_jobs

    using_session(:watcher) do
      assert_text "Carla Nunes"
    end
  end

  test "the dashboard counters follow what another admin creates" do
    actor = create(:user, :admin)
    watcher = create(:user, :admin)

    using_session(:watcher) do
      sign_in_as watcher
      visit admin_dashboard_path

      assert_selector "#total_users_count", text: "2"
    end

    sign_in_as actor
    create_user_through_the_form

    perform_all_enqueued_jobs

    # The dashboard has its blocks replaced one by one, instead of the page refresh
    # the lists use.
    using_session(:watcher) do
      assert_selector "#total_users_count", text: "3"
      assert_selector "#recent_users", text: "Carla Nunes"
    end
  end

  private

  def create_user_through_the_form(full_name: "Carla Nunes", email: "carla@example.com")
    visit new_admin_user_path

    fill_in I18n.t("admin.users.form.full_name"), with: full_name
    fill_in I18n.t("admin.users.form.email"), with: email
    fill_in I18n.t("admin.users.form.password"), with: "password123"
    fill_in I18n.t("admin.users.form.password_confirmation"), with: "password123"
    click_on I18n.t("admin.users.new.submit")

    assert_text I18n.t("admin.users.create.success")
  end
end
