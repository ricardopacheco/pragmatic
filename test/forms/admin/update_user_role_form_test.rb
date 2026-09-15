# frozen_string_literal: true

require "test_helper"

module Admin
  class UpdateUserRoleFormTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
      @user = create(:user)
    end

    test "fails when the role is blank" do
      form = UpdateUserRoleForm.new(role: "")

      assert_not form.submit(@admin.id, @user.id)
      assert_includes form.errors[:role], I18n.t("contracts.errors.key?")
    end

    test "fails when the role is not a valid role" do
      form = UpdateUserRoleForm.new(role: "owner")

      assert_not form.submit(@admin.id, @user.id)
      assert_includes form.errors[:role],
        I18n.t("contracts.errors.included_in?.arg.default", list: User.roles.keys.join(", "))
    end

    test "copies operation errors to base when the admin is not an admin" do
      form = UpdateUserRoleForm.new(role: "admin")

      assert_not form.submit(create(:user).id, @user.id)
      assert_includes form.errors[:base], I18n.t("operations.base.user_is_not_admin")
    end

    test "succeeds and promotes the user" do
      form = UpdateUserRoleForm.new(role: "admin")

      assert form.submit(@admin.id, @user.id)
      assert_predicate @user.reload, :admin?
      assert_equal @user, form.user
    end
  end
end
