# frozen_string_literal: true

require "test_helper"

module Profile
  class UpdatePasswordOperationTest < ActiveSupport::TestCase
    setup do
      @operation = UpdatePasswordOperation.new
      @user = create(:user, password: "password")
    end

    test "fails when the user does not exist" do
      result = @operation.call(nil, valid_attributes)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
    end

    test "fails when attributes are blank" do
      result = @operation.call(@user.id, {})

      assert_predicate result, :failure?
      assert_includes result.failure[:current_password], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:password], I18n.t("contracts.errors.key?")
    end

    test "fails when the current password is wrong" do
      result = @operation.call(@user.id, valid_attributes.merge(current_password: "wrong-password"))

      assert_predicate result, :failure?
      assert_includes result.failure[:current_password], I18n.t("errors.messages.invalid")
    end

    test "fails when the confirmation does not match" do
      result = @operation.call(@user.id, valid_attributes.merge(password_confirmation: "different"))

      assert_predicate result, :failure?
      assert_includes result.failure[:password_confirmation],
        I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
    end

    test "fails with the model errors when the password cannot be saved" do
      User.any_instance.stubs(:update).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:password, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      result = @operation.call(@user.id, valid_attributes)

      assert_predicate result, :failure?
      assert_includes result.failure[:password], I18n.t("errors.messages.invalid")
    end

    test "does not change the password when the operation fails" do
      @operation.call(@user.id, valid_attributes.merge(current_password: "wrong-password"))

      assert @user.reload.authenticate("password")
    end

    test "succeeds and changes the password" do
      result = @operation.call(@user.id, valid_attributes)

      assert_predicate result, :success?
      assert @user.reload.authenticate("new-password")
    end

    private

    def valid_attributes
      {current_password: "password", password: "new-password", password_confirmation: "new-password"}
    end
  end
end
