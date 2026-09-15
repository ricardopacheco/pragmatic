# frozen_string_literal: true

require "test_helper"

module Profile
  class UpdateProfileContractTest < ActiveSupport::TestCase
    setup do
      @contract = UpdateProfileContract.new
      @user = create(:user, email: "jane@example.com")
    end

    test "fails when attributes are blank" do
      result = @contract.call({full_name: "", email: ""}, user: @user)

      assert_predicate result, :failure?
      assert_includes result.errors[:full_name], I18n.t("contracts.errors.key?")
      assert_includes result.errors[:email], I18n.t("contracts.errors.key?")
    end

    test "fails when full_name has a length out of range" do
      length = Rails.configuration.x.validations.full_name_length
      result = @contract.call({full_name: "A", email: @user.email}, user: @user)

      assert_predicate result, :failure?
      assert_includes result.errors[:full_name],
        I18n.t("contracts.errors.custom.macro.full_name_format", min: length.min, max: length.max)
    end

    test "fails when email has an invalid format" do
      result = @contract.call({full_name: @user.full_name, email: "invalid_email"}, user: @user)

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "fails when remove_avatar_image is not a boolean" do
      result = @contract.call(
        {full_name: @user.full_name, email: @user.email, remove_avatar_image: "maybe"}, user: @user
      )

      assert_predicate result, :failure?
      assert_includes result.errors[:remove_avatar_image], I18n.t("contracts.errors.bool?")
    end

    test "fails when email already belongs to another user" do
      create(:user, email: "taken@example.com")
      result = @contract.call({full_name: @user.full_name, email: "TAKEN@example.com"}, user: @user)

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("errors.messages.taken")
    end

    test "succeeds when keeping the user's own email" do
      result = @contract.call({full_name: "Jane Cooper", email: "JANE@example.com"}, user: @user)

      assert_predicate result, :success?
      assert_empty result.errors
    end

    test "ignores attributes that are not declared" do
      result = @contract.call({full_name: @user.full_name, email: @user.email, role: "admin"}, user: @user)

      assert_predicate result, :success?
      assert_not result.to_h.key?(:role)
    end

    test "succeeds when attributes are valid" do
      result = @contract.call(
        {full_name: "Jane Cooper", email: "jane.cooper@example.com", remove_avatar_image: "1"}, user: @user
      )

      assert_predicate result, :success?
      assert_empty result.errors
      assert_equal true, result[:remove_avatar_image]
    end
  end
end
