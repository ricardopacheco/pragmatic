# frozen_string_literal: true

require "test_helper"

module Guest
  class RegisterOperationTest < ActiveSupport::TestCase
    setup do
      @operation = RegisterOperation.new
    end

    test "fails when attributes are blank" do
      result = @operation.call({})

      assert_predicate result, :failure?
      assert_includes result.failure[:full_name], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:email], I18n.t("contracts.errors.key?")
    end

    test "fails when the email already belongs to another user" do
      create(:user, email: "taken@example.com")
      result = @operation.call(attributes_for(:user, email: "taken@example.com"))

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("errors.messages.taken")
    end

    test "fails with the model errors when the record cannot be saved" do
      invalid_user = build(:user)
      invalid_user.errors.add(:email, I18n.t("errors.messages.taken"))
      User.stubs(:new).returns(invalid_user)
      invalid_user.stubs(:save).returns(false)

      result = @operation.call(attributes_for(:user))

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("errors.messages.taken")
    end

    test "does not create the user when the operation fails" do
      assert_no_difference -> { User.count } do
        @operation.call({})
      end
    end

    test "succeeds and creates a regular user" do
      result = nil

      assert_difference -> { User.count }, 1 do
        result = @operation.call(attributes_for(:user))
      end

      assert_predicate result, :success?
      assert_predicate result.value!, :profile?
    end

    test "ignores a role sent by the visitor" do
      result = @operation.call(attributes_for(:user, role: "admin"))

      assert_predicate result, :success?
      assert_predicate result.value!, :profile?
    end

    test "enqueues the broadcast job" do
      assert_enqueued_with(job: Guest::RegisterUserBroadcastJob, queue: "broadcast") do
        @operation.call(attributes_for(:user))
      end
    end
  end
end
