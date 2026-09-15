# frozen_string_literal: true

require "test_helper"

module Admin
  class UpdateUserRoleContractTest < ActiveSupport::TestCase
    setup do
      @contract = UpdateUserRoleContract.new
    end

    test "fails when role is blank" do
      result = @contract.call(role: "")

      assert_predicate result, :failure?
      assert_includes result.errors[:role], I18n.t("contracts.errors.key?")
    end

    test "fails when role is not a valid role" do
      result = @contract.call(role: "owner")

      assert_predicate result, :failure?
      assert_includes result.errors[:role],
        I18n.t("contracts.errors.included_in?.arg.default", list: User.roles.keys.join(", "))
    end

    test "succeeds when role is admin" do
      result = @contract.call(role: "admin")

      assert_predicate result, :success?
      assert_empty result.errors
    end

    test "succeeds when role is profile" do
      result = @contract.call(role: "profile")

      assert_predicate result, :success?
      assert_empty result.errors
    end
  end
end
