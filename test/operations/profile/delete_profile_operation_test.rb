# frozen_string_literal: true

require "test_helper"

module Profile
  class DeleteProfileOperationTest < ActiveSupport::TestCase
    setup do
      @operation = DeleteProfileOperation.new
      @user = create(:user)
    end

    test "fails when the user does not exist" do
      result = @operation.call(nil)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
    end

    test "fails with the model errors when the record cannot be destroyed" do
      User.any_instance.stubs(:destroy).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:base, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      result = @operation.call(@user.id)

      assert_predicate result, :failure?
      assert_includes result.failure[:base], I18n.t("errors.messages.invalid")
    end

    test "does not delete the user when the operation fails" do
      assert_no_difference -> { User.count } do
        @operation.call(nil)
      end
    end

    test "succeeds and deletes the user" do
      result = nil

      assert_difference -> { User.count }, -1 do
        result = @operation.call(@user.id)
      end

      assert_predicate result, :success?
      assert_nil result.value!
    end

    test "deletes the sessions of the user" do
      @user.sessions.create!(ip_address: "203.0.113.7", user_agent: "Test")

      assert_difference -> { Session.count }, -1 do
        @operation.call(@user.id)
      end
    end

    test "sends the deletion email to whoever deleted the account" do
      assert_enqueued_email_with AccountMailer, :deleted,
        args: [{full_name: @user.full_name, email: @user.email}] do
        @operation.call(@user.id)
      end
    end

    test "does not send the deletion email when the operation fails" do
      assert_no_enqueued_emails do
        @operation.call(nil)
      end
    end
  end
end
