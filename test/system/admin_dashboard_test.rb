# frozen_string_literal: true

require "application_system_test_case"

# The dashboard: the counters by role, the capped list of recent users and the card
# for the latest spreadsheet.
class AdminDashboardTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, full_name: "Ada Prado")
  end

  test "the counters show how many users there are, by role" do
    create_list(:user, 2)

    sign_in_as @admin

    assert_current_path admin_dashboard_path
    assert_selector "#total_users_count", text: "3"
    assert_selector "#admins_count", text: "1"
    assert_selector "#regular_users_count", text: "2"
  end

  test "the recent users list stops at the most recent ones" do
    create_list(:user, Admin::DashboardsController::RECENT_USERS)

    sign_in_as @admin

    # One more user exists than the list shows, so the cap is what is being read here.
    assert_selector "#recent_users li", count: Admin::DashboardsController::RECENT_USERS
  end

  test "with no imports the dashboard offers to start one" do
    sign_in_as @admin

    within("#latest_import") do
      assert_text I18n.t("admin.dashboards.no_imports.heading")
      assert_link I18n.t("admin.dashboards.no_imports.action")
    end
  end

  test "the card shows the latest spreadsheet and its status" do
    create(:import, user: @admin)

    sign_in_as @admin

    within("#latest_import") do
      assert_text "users.csv"
      assert_text I18n.t("decorators.import.statuses.queued")
    end
  end
end
