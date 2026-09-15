# frozen_string_literal: true

require "test_helper"

module Guest
  class ResetPasswordContractTest < ActiveSupport::TestCase
    setup do
      @contract = ResetPasswordContract.new
    end

    test "fails when attributes are blank" do
      result = @contract.call({})

      assert_predicate result, :failure?
      %i[token password password_confirmation].each do |attribute|
        assert_includes result.errors[attribute], I18n.t("contracts.errors.key?")
      end
    end

    test "fails when password has a length out of range" do
      length = Rails.configuration.x.validations.password_length
      result = @contract.call(token: create(:user).password_reset_token, password: "short", password_confirmation: "short")

      assert_predicate result, :failure?
      assert_includes result.errors[:password],
        I18n.t("contracts.errors.custom.macro.password_format", min: length.min, max: length.max)
    end

    test "fails when password confirmation does not match" do
      result = @contract.call(
        token: create(:user).password_reset_token, password: "new-password", password_confirmation: "different"
      )

      assert_predicate result, :failure?
      assert_includes result.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "fails when token is invalid" do
      result = @contract.call(token: "invalid-token", password: "new-password", password_confirmation: "new-password")

      assert_predicate result, :failure?
      assert_includes result.errors[nil], I18n.t("contracts.errors.custom.password_reset.invalid_token")
    end

    test "fails when token has expired" do
      user = create(:user)
      token = user.password_reset_token

      travel 16.minutes do
        result = @contract.call(token:, password: "new-password", password_confirmation: "new-password")

        assert_predicate result, :failure?
        assert_includes result.errors[nil], I18n.t("contracts.errors.custom.password_reset.invalid_token")
      end
    end

    test "succeeds when token and passwords are valid" do
      user = create(:user)
      result = @contract.call(token: user.password_reset_token, password: "new-password", password_confirmation: "new-password")

      assert_predicate result, :success?
      assert_empty result.errors
      assert_equal user, result.context[:user]
    end
  end
end
