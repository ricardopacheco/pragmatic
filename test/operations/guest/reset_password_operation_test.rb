# frozen_string_literal: true

require "test_helper"

module Guest
  class ResetPasswordOperationTest < ActiveSupport::TestCase
    setup do
      @operation = ResetPasswordOperation.new
      @user = create(:user)
    end

    test "fails when attributes are blank" do
      result = @operation.call({})

      assert_predicate result, :failure?
      assert_includes result.failure[:token], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:password], I18n.t("contracts.errors.key?")
    end

    test "fails when the token is invalid" do
      result = @operation.call(valid_attributes.merge(token: "invalid-token"))

      assert_predicate result, :failure?
      assert_includes result.failure[nil], I18n.t("contracts.errors.custom.password_reset.invalid_token")
    end

    test "fails with the model errors when the password cannot be saved" do
      User.any_instance.stubs(:update).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:password, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      result = @operation.call(valid_attributes)

      assert_predicate result, :failure?
      assert_includes result.failure[:password], I18n.t("errors.messages.invalid")
    end

    test "succeeds and changes the password" do
      result = @operation.call(valid_attributes)

      assert_predicate result, :success?
      assert @user.reload.authenticate("new-password")
    end

    test "succeeds and signs the user out everywhere" do
      @user.sessions.create!(ip_address: "203.0.113.7", user_agent: "Test")

      assert_difference -> { @user.sessions.count }, -1 do
        @operation.call(valid_attributes)
      end
    end

    private

    def valid_attributes
      {token: @user.password_reset_token, password: "new-password", password_confirmation: "new-password"}
    end
  end
end
