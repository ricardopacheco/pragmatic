# frozen_string_literal: true

require "test_helper"

module Admin
  class CreateUserOperationTest < ActiveSupport::TestCase
    setup do
      @operation = CreateUserOperation.new
      @admin = create(:user, :admin)
    end

    test "fails when the admin does not exist" do
      result = @operation.call(nil, attributes_for(:user))

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.admin_not_found"), result.failure[:base]
    end

    test "fails when the user is not an admin" do
      result = @operation.call(create(:user).id, attributes_for(:user))

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_is_not_admin"), result.failure[:base]
    end

    test "fails when attributes are blank" do
      result = @operation.call(@admin.id, {})

      assert_predicate result, :failure?
      assert_includes result.failure[:full_name], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:role], I18n.t("contracts.errors.key?")
    end

    test "fails when the email already belongs to another user" do
      create(:user, email: "taken@example.com")
      result = @operation.call(@admin.id, attributes_for(:user, email: "taken@example.com"))

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("errors.messages.taken")
    end

    test "fails with the model errors when the record cannot be saved" do
      invalid_user = build(:user)
      invalid_user.errors.add(:email, I18n.t("errors.messages.taken"))
      User.stubs(:new).returns(invalid_user)
      invalid_user.stubs(:save).returns(false)

      result = @operation.call(@admin.id, attributes_for(:user))

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("errors.messages.taken")
    end

    test "does not create the user when the operation fails" do
      assert_no_difference -> { User.count } do
        @operation.call(@admin.id, {})
      end
    end

    test "succeeds and creates a regular user" do
      result = nil

      assert_difference -> { User.count }, 1 do
        result = @operation.call(@admin.id, attributes_for(:user))
      end

      assert_predicate result, :success?
      assert_predicate result.value!, :profile?
    end

    test "succeeds and creates an admin" do
      result = @operation.call(@admin.id, attributes_for(:user, :admin))

      assert_predicate result, :success?
      assert_predicate result.value!, :admin?
    end
  end
end
