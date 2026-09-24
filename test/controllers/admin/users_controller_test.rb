# frozen_string_literal: true

require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      sign_in_as(@admin)
    end

    test "rejects a regular user" do
      sign_out
      sign_in_as(create(:user))

      get admin_users_path

      assert_redirected_to profile_path
    end

    test "index lists the users" do
      create(:user)

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
      user = create(:user)

      get admin_users_path(query: user.full_name)

      assert_response :success
      assert_select "#users_list tr", 1
      assert_select "#users_list", text: /#{Regexp.escape(user.full_name)}/
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

    test "new renders an empty form that requires the password" do
      get new_admin_user_path

      assert_response :success
      assert_select "h1", I18n.t("admin.users.new.heading")
      assert_select "input[name=?][required]", "user[password]"
    end

    test "create adds a user" do
      assert_difference -> { User.count }, 1 do
        post admin_users_path, params: {user: valid_attributes}
      end

      assert_redirected_to admin_users_path
      assert_equal I18n.t("admin.users.create.success"), flash[:notice]
      assert_predicate User.find_by(email: "jane@example.com"), :profile?
    end

    test "create rejects invalid data" do
      assert_no_difference -> { User.count } do
        post admin_users_path, params: {user: valid_attributes.merge(email: "invalid_email")}
      end

      assert_response :unprocessable_entity
    end

    test "edit renders the form with the user data" do
      user = create(:user)

      get edit_admin_user_path(user)

      assert_response :success
      assert_select "input[value=?]", user.full_name
    end

    test "update changes the user" do
      user = create(:user)

      patch admin_user_path(user), params: {user: {full_name: "Jane C.", email: user.email, role: "admin"}}

      assert_redirected_to admin_users_path
      assert_equal "Jane C.", user.reload.full_name
      assert_predicate user, :admin?
    end

    test "update rejects invalid data" do
      user = create(:user)
      taken = create(:user)

      assert_no_changes -> { user.reload.full_name } do
        patch admin_user_path(user), params: {user: {full_name: "Jane C.", email: taken.email, role: "profile"}}
      end

      assert_response :unprocessable_entity
    end

    test "destroy deletes the user" do
      user = create(:user)

      assert_difference -> { User.count }, -1 do
        delete admin_user_path(user)
      end

      assert_redirected_to admin_users_path
      assert_equal I18n.t("admin.users.destroy.success"), flash[:notice]
    end

    private

    def valid_attributes
      {
        full_name: "Jane Cooper",
        email: "jane@example.com",
        role: "profile",
        password: "password",
        password_confirmation: "password"
      }
    end
  end
end
