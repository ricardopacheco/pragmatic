# frozen_string_literal: true

require "test_helper"

module Guest
  class RequestPasswordResetFormTest < ActiveSupport::TestCase
    test "is named Password, so form_with generates password fields" do
      assert_equal "password", RequestPasswordResetForm.model_name.param_key
    end

    test "fails when the email has an invalid format" do
      form = RequestPasswordResetForm.new(email: "invalid_email")

      assert_not form.submit
      assert_includes form.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "succeeds without sending an email when the address is not registered" do
      form = RequestPasswordResetForm.new(email: "notfound@example.com")
      submitted = nil

      assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
        submitted = form.submit
      end

      assert submitted
      assert_empty form.errors
    end

    test "succeeds and sends the reset email when the user exists" do
      user = create(:user)
      form = RequestPasswordResetForm.new(email: user.email)

      assert_enqueued_emails 1 do
        assert form.submit
      end
    end
  end
end
