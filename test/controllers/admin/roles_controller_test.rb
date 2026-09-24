# frozen_string_literal: true

require "test_helper"

module Admin
  class RolesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(create(:user, :admin))
    end

    test "update changes the role of the user" do
      user = create(:user)

      patch admin_user_role_path(user), params: {user: {role: "admin"}}

      assert_redirected_to admin_users_path
      assert_equal I18n.t("admin.roles.update.success", name: user.full_name), flash[:notice]
      assert_predicate user.reload, :admin?
    end

    test "update rejects an invalid role" do
      user = create(:user)

      patch admin_user_role_path(user), params: {user: {role: "owner"}}

      assert_redirected_to admin_users_path
      assert_predicate flash[:alert], :present?
      assert_predicate user.reload, :profile?
    end

    test "update rejects an unknown user" do
      patch admin_user_role_path(user_id: 0), params: {user: {role: "admin"}}

      assert_redirected_to admin_users_path
      assert_equal I18n.t("operations.base.user_not_found"), flash[:alert]
    end
  end
end
