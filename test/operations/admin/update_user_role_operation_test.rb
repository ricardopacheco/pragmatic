# frozen_string_literal: true

require "test_helper"

module Admin
  class UpdateUserRoleOperationTest < ActiveSupport::TestCase
    setup do
      @operation = UpdateUserRoleOperation.new
      @admin = create(:user, :admin)
      @user = create(:user)
    end

    test "fails when the admin does not exist" do
      result = @operation.call(nil, @user.id, role: "admin")

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.admin_not_found"), result.failure[:base]
    end

    test "fails when the user is not an admin" do
      result = @operation.call(create(:user).id, @user.id, role: "admin")

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_is_not_admin"), result.failure[:base]
    end

    test "fails when the edited user does not exist" do
      result = @operation.call(@admin.id, nil, role: "admin")

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
    end

    test "fails when the role is not a valid role" do
      result = @operation.call(@admin.id, @user.id, role: "owner")

      assert_predicate result, :failure?
      assert_includes result.failure[:role],
        I18n.t("contracts.errors.included_in?.arg.default", list: User.roles.keys.join(", "))
    end

    test "does not change the role when the operation fails" do
      assert_no_changes -> { @user.reload.role } do
        @operation.call(@admin.id, @user.id, role: "owner")
      end
    end

    test "succeeds and promotes the user to admin" do
      result = @operation.call(@admin.id, @user.id, role: "admin")

      assert_predicate result, :success?
      assert_predicate @user.reload, :admin?
    end

    test "succeeds and demotes another admin" do
      other_admin = create(:user, :admin)
      result = @operation.call(@admin.id, other_admin.id, role: "profile")

      assert_predicate result, :success?
      assert_predicate other_admin.reload, :profile?
    end
  end
end
