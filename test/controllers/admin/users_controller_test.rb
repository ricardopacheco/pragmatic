# frozen_string_literal: true

require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin, full_name: "Robert Fox")
      sign_in_as(@admin)
    end

    test "rejects a regular user" do
      sign_out
      sign_in_as(create(:user))

      get admin_users_path

      assert_redirected_to profile_path
    end

    test "index lists the users" do
      create(:user, full_name: "Jane Cooper")

      get admin_users_path

      assert_response :success
      assert_select "#users_list tr", 2
    end

    test "index shows the empty state when nothing matches the search" do
      get admin_users_path(query: "nobody")

      assert_response :success
      assert_select "#users_list", false
      assert_select "h2", text: I18n.t("admin.users.empty.heading")
    end

    test "index filters by name" do
      create(:user, full_name: "Jane Cooper")

      get admin_users_path(query: "jane")

      assert_response :success
      assert_select "#users_list tr", 1
    end

    test "index filters by role" do
      create_list(:user, 2)

      get admin_users_path(role: "admin")

      assert_response :success
      assert_select "#users_list tr", 1
    end

    test "index paginates" do
      create_list(:user, UsersController::PER_PAGE)

      get admin_users_path

      assert_response :success
      assert_select "#users_list tr", UsersController::PER_PAGE
      assert_select "nav[aria-label=?] a", I18n.t("admin.users.pagination.pagination")
    end
  end
end
