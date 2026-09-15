# frozen_string_literal: true

require "test_helper"

module Profile
  class UpdatePasswordContractTest < ActiveSupport::TestCase
    setup do
      @contract = UpdatePasswordContract.new
      @user = create(:user, password: "password")
    end

    test "fails when attributes are blank" do
      result = @contract.call({}, user: @user)

      assert_predicate result, :failure?
      %i[current_password password password_confirmation].each do |attribute|
        assert_includes result.errors[attribute], I18n.t("contracts.errors.key?")
      end
    end

    test "fails when password has a length out of range" do
      length = Rails.configuration.x.validations.password_length
      result = @contract.call(
        {current_password: "password", password: "short", password_confirmation: "short"}, user: @user
      )

      assert_predicate result, :failure?
      assert_includes result.errors[:password],
        I18n.t("contracts.errors.custom.macro.password_format", min: length.min, max: length.max)
    end

    test "fails when password confirmation does not match" do
      result = @contract.call(
        {current_password: "password", password: "new-password", password_confirmation: "different"}, user: @user
      )

      assert_predicate result, :failure?
      assert_includes result.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "fails when current password is wrong" do
      result = @contract.call(
        {current_password: "wrong-password", password: "new-password", password_confirmation: "new-password"},
        user: @user
      )

      assert_predicate result, :failure?
      assert_includes result.errors[:current_password], I18n.t("errors.messages.invalid")
    end

    test "fails when there is no user in the context" do
      result = @contract.call(
        current_password: "password", password: "new-password", password_confirmation: "new-password"
      )

      assert_predicate result, :failure?
      assert_includes result.errors[:current_password], I18n.t("errors.messages.invalid")
    end

    test "succeeds when current password and new password are valid" do
      result = @contract.call(
        {current_password: "password", password: "new-password", password_confirmation: "new-password"},
        user: @user
      )

      assert_predicate result, :success?
      assert_empty result.errors
    end
  end
end
