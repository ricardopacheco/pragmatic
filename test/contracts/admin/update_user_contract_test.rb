# frozen_string_literal: true

require "test_helper"

module Admin
  class UpdateUserContractTest < ActiveSupport::TestCase
    setup do
      @contract = UpdateUserContract.new
      @user = create(:user, email: "jane@example.com")
    end

    test "fails when attributes are blank" do
      result = call_contract(full_name: "", email: "", role: "")

      assert_predicate result, :failure?
      %i[full_name email role].each do |attribute|
        assert_includes result.errors[attribute], I18n.t("contracts.errors.key?")
      end
    end

    test "fails when full_name has a length out of range" do
      length = Rails.configuration.x.validations.full_name_length
      result = call_contract(valid_attributes.merge(full_name: "A"))

      assert_predicate result, :failure?
      assert_includes result.errors[:full_name],
        I18n.t("contracts.errors.custom.macro.full_name_format", min: length.min, max: length.max)
    end

    test "fails when email has an invalid format" do
      result = call_contract(valid_attributes.merge(email: "invalid_email"))

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
    end

    test "fails when role is not a valid role" do
      result = call_contract(valid_attributes.merge(role: "owner"))

      assert_predicate result, :failure?
      assert_includes result.errors[:role],
        I18n.t("contracts.errors.included_in?.arg.default", list: User.roles.keys.join(", "))
    end

    test "fails when password has a length out of range" do
      length = Rails.configuration.x.validations.password_length
      result = call_contract(valid_attributes.merge(password: "short", password_confirmation: "short"))

      assert_predicate result, :failure?
      assert_includes result.errors[:password],
        I18n.t("contracts.errors.custom.macro.password_format", min: length.min, max: length.max)
    end

    test "fails when password confirmation does not match" do
      result = call_contract(valid_attributes.merge(password: "new-password", password_confirmation: "different"))

      assert_predicate result, :failure?
      assert_includes result.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "fails when password is sent without confirmation" do
      result = call_contract(valid_attributes.merge(password: "new-password"))

      assert_predicate result, :failure?
      assert_includes result.errors[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "fails when remove_avatar_image is not a boolean" do
      result = call_contract(valid_attributes.merge(remove_avatar_image: "maybe"))

      assert_predicate result, :failure?
      assert_includes result.errors[:remove_avatar_image], I18n.t("contracts.errors.bool?")
    end

    test "fails when email already belongs to another user" do
      other_user = create(:user)
      result = call_contract(valid_attributes.merge(email: other_user.email.upcase))

      assert_predicate result, :failure?
      assert_includes result.errors[:email], I18n.t("errors.messages.taken")
    end

    test "succeeds when keeping the user's own email and password" do
      result = call_contract(valid_attributes.merge(email: "JANE@example.com"))

      assert_predicate result, :success?
      assert_empty result.errors
    end

    test "succeeds when changing role, password and avatar" do
      result = call_contract(
        valid_attributes.merge(
          role: "admin", password: "new-password", password_confirmation: "new-password", remove_avatar_image: "1"
        )
      )

      assert_predicate result, :success?
      assert_empty result.errors
      assert_equal true, result[:remove_avatar_image]
    end

    private

    def valid_attributes
      {full_name: "Jane Cooper", email: @user.email, role: "profile"}
    end

    def call_contract(attributes)
      @contract.call(attributes, user: @user)
    end
  end
end
