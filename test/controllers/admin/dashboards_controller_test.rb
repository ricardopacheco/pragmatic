# frozen_string_literal: true

require "test_helper"

module Admin
  class DashboardsControllerTest < ActionDispatch::IntegrationTest
    setup { @admin = create(:user, :admin) }

    test "requires an authenticated user" do
      get admin_dashboard_path

      assert_redirected_to new_session_path
    end

    test "rejects a regular user" do
      sign_in_as(create(:user))

      get admin_dashboard_path

      assert_redirected_to profile_path
      assert_equal I18n.t("admin.unauthorized"), flash[:alert]
    end

    test "shows the counters and the empty import card" do
      create_list(:user, 2)
      sign_in_as(@admin)

      get admin_dashboard_path

      assert_response :success
      assert_select "#total_users_count", "3"
      assert_select "#admins_count", "1"
      assert_select "#regular_users_count", "2"
      assert_select "#latest_import", text: /#{I18n.t("admin.dashboards.no_imports.heading")}/
    end

    test "shows the latest import when there is one" do
      create(:import, user: @admin)
      sign_in_as(@admin)

      get admin_dashboard_path

      assert_response :success
      assert_select "#latest_import", text: /users\.csv/
    end
  end
end
