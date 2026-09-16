# frozen_string_literal: true

require "test_helper"

module Admin
  class DeleteUserOperationTest < ActiveSupport::TestCase
    setup do
      @operation = DeleteUserOperation.new
      @admin = create(:user, :admin)
      @user = create(:user)
    end

    test "fails when the admin does not exist" do
      result = @operation.call(nil, @user.id)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.admin_not_found"), result.failure[:base]
    end

    test "fails when the user is not an admin" do
      result = @operation.call(create(:user).id, @user.id)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_is_not_admin"), result.failure[:base]
    end

    test "fails when the deleted user does not exist" do
      result = @operation.call(@admin.id, nil)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
    end

    test "fails with the model errors when the record cannot be destroyed" do
      User.any_instance.stubs(:destroy).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:base, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      result = @operation.call(@admin.id, @user.id)

      assert_predicate result, :failure?
      assert_includes result.failure[:base], I18n.t("errors.messages.invalid")
    end

    test "does not delete the user when the operation fails" do
      non_admin = create(:user)

      assert_no_difference -> { User.count } do
        @operation.call(non_admin.id, @user.id)
      end
    end

    test "succeeds and deletes the user" do
      result = nil

      assert_difference -> { User.count }, -1 do
        result = @operation.call(@admin.id, @user.id)
      end

      assert_predicate result, :success?
      assert_nil result.value!
    end

    test "enqueues the broadcast job" do
      assert_enqueued_with(job: Admin::DeleteUserBroadcastJob, queue: "broadcast") do
        @operation.call(@admin.id, @user.id)
      end
    end

    test "sends the deletion email to whoever was removed" do
      assert_enqueued_email_with AccountMailer, :deleted,
        args: [{full_name: @user.full_name, email: @user.email}] do
        @operation.call(@admin.id, @user.id)
      end
    end

    test "does not send the deletion email when the operation fails" do
      assert_no_enqueued_emails do
        @operation.call(create(:user).id, @user.id)
      end
    end
  end
end
