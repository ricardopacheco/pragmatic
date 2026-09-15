# frozen_string_literal: true

require "test_helper"

module Admin
  class CreateUserContractTest < ActiveSupport::TestCase
    setup do
      @contract = CreateUserContract.new
    end

    test "fails when attributes are blank" do
      result = @contract.call({})

      assert_predicate result, :failure?
      %i[full_name email role password password_confirmation].each do |attribute|
        assert_includes result.errors[attribute], I18n.t("contracts.errors.key?")
      end
    end

    test "fails when full_name has a length out of range" do
      length = Rails.configuration.x.validations.full_name_length
      result = @contract.call(attributes_for(:user, full_name: "A"))

      assert_predicate result, :failure?
      assert_includes result.errors[:full_name],
        I18n.t("contracts.errors.custom.macro.full_name_format", min: length.min, max: length.max)
    end

    test "fails when email has an invalid format" do
      result = @contract.call(attributes_for(:user, email: "invalid_email"))

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "fails when role is not a valid role" do
      result = @contract.call(attributes_for(:user, role: "owner"))

      assert_predicate result, :failure?
      assert_includes result.errors[:role],
        I18n.t("contracts.errors.included_in?.arg.default", list: User.roles.keys.join(", "))
    end

    test "fails when password has a length out of range" do
      length = Rails.configuration.x.validations.password_length
      result = @contract.call(attributes_for(:user, password: "short", password_confirmation: "short"))

      assert_predicate result, :failure?
      assert_includes result.errors[:password],
        I18n.t("contracts.errors.custom.macro.password_format", min: length.min, max: length.max)
    end

    test "fails when password confirmation does not match" do
      result = @contract.call(attributes_for(:user, password_confirmation: "different"))

      assert_predicate result, :failure?
      assert_includes result.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "fails when email already belongs to another user" do
      create(:user, email: "taken@example.com")
      result = @contract.call(attributes_for(:user, email: "TAKEN@example.com"))

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("errors.messages.taken")
    end

    test "succeeds when creating a profile user" do
      result = @contract.call(attributes_for(:user))

      assert_predicate result, :success?
      assert_empty result.errors
      assert_equal "profile", result[:role]
    end

    test "succeeds when creating an admin" do
      result = @contract.call(attributes_for(:user, :admin))

      assert_predicate result, :success?
      assert_empty result.errors
      assert_equal "admin", result[:role]
    end
  end
end
