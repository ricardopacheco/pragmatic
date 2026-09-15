# frozen_string_literal: true

require "test_helper"

module Guest
  class RequestPasswordResetOperationTest < ActiveSupport::TestCase
    setup do
      @operation = RequestPasswordResetOperation.new
    end

    test "fails when the email is blank" do
      result = @operation.call(email: "")

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("contracts.errors.key?")
    end

    test "fails when the email has an invalid format" do
      result = @operation.call(email: "invalid_email")

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "succeeds without sending an email when the address is not registered" do
      result = nil

      assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
        result = @operation.call(email: "notfound@example.com")
      end

      assert_predicate result, :success?
    end

    test "succeeds and sends the reset email when the user exists" do
      user = create(:user)
      result = nil

      assert_enqueued_emails 1 do
        result = @operation.call(email: user.email.upcase)
      end

      assert_predicate result, :success?
    end
  end
end
