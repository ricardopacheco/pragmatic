# frozen_string_literal: true

require "test_helper"

class ApplicationOperationTest < ActiveSupport::TestCase
  # Runs a single shared step, so the private steps can be tested directly.
  class StepsOperation < ApplicationOperation
    def call(step, *args, **kwargs)
      send(step, *args, **kwargs)
    end
  end

  setup do
    @operation = StepsOperation.new
  end

  test "self.call without a block returns the result" do
    result = StepsOperation.call(:find_user, create(:user).id)

    assert_predicate result, :success?
  end

  test "self.call with a block matches the success branch" do
    user = create(:user)
    matched_success = nil
    matched_failure = nil

    StepsOperation.call(:find_user, user.id) do |result|
      result.success { |value| matched_success = value }
      result.failure { |errors| matched_failure = errors }
    end

    assert_equal user, matched_success
    assert_nil matched_failure
  end

  test "self.call with a block matches the failure branch" do
    matched_success = nil
    matched_failure = nil

    StepsOperation.call(:find_user, nil) do |result|
      result.success { |value| matched_success = value }
      result.failure { |errors| matched_failure = errors }
    end

    assert_nil matched_success
    assert_equal I18n.t("operations.base.user_not_found"), matched_failure[:base]
  end

  test "self.call forwards positional and keyword arguments" do
    user = create(:user)
    result = StepsOperation.call(:update_user_on_database, user, full_name: "New Name")

    assert_predicate result, :success?
    assert_equal "New Name", user.reload.full_name
  end

  test "validate_contract fails with the contract errors as a hash" do
    result = @operation.call(:validate_contract, Guest::RequestPasswordResetContract, {})

    assert_predicate result, :failure?
    assert_includes result.failure[:email], I18n.t("contracts.errors.key?")
  end

  test "validate_contract succeeds with the contract result and its context" do
    user = create(:user)
    result = @operation.call(
      :validate_contract, Guest::AuthenticationContract, {email: user.email, password: "password"}
    )

    assert_predicate result, :success?
    assert_equal user.email, result.value!.to_h[:email]
    assert_equal user, result.value!.context[:user]
  end

  test "validate_contract forwards the context to the contract" do
    user = create(:user, email: "jane@example.com")
    attributes = {full_name: "Jane Cooper", email: "JANE@example.com"}

    result = @operation.call(:validate_contract, Profile::UpdateProfileContract, attributes, user:)

    assert_predicate result, :success?
  end

  test "create_user_on_database fails with the model errors as a hash" do
    create(:user, email: "taken@example.com")
    result = @operation.call(:create_user_on_database, attributes_for(:user, email: "taken@example.com"))

    assert_predicate result, :failure?
    assert_includes result.failure[:email], I18n.t("errors.messages.taken")
  end

  test "create_user_on_database succeeds and persists the user" do
    result = nil

    assert_difference -> { User.count }, 1 do
      result = @operation.call(:create_user_on_database, attributes_for(:user))
    end

    assert_predicate result, :success?
    assert_predicate result.value!, :persisted?
  end

  test "update_user_on_database fails with the model errors as a hash" do
    create(:user, email: "taken@example.com")
    result = @operation.call(:update_user_on_database, create(:user), email: "taken@example.com")

    assert_predicate result, :failure?
    assert_includes result.failure[:email], I18n.t("errors.messages.taken")
  end

  test "update_user_on_database succeeds and saves the changes" do
    user = create(:user)
    result = @operation.call(:update_user_on_database, user, full_name: "Jane Cooper")

    assert_predicate result, :success?
    assert_equal "Jane Cooper", user.reload.full_name
  end

  test "find_user fails when the user does not exist" do
    result = @operation.call(:find_user, nil)

    assert_predicate result, :failure?
    assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
  end

  test "find_user succeeds when the user exists" do
    user = create(:user)
    result = @operation.call(:find_user, user.id)

    assert_predicate result, :success?
    assert_equal user, result.value!
  end

  test "find_and_validate_user_admin fails when the admin does not exist" do
    result = @operation.call(:find_and_validate_user_admin, nil)

    assert_predicate result, :failure?
    assert_equal I18n.t("operations.base.admin_not_found"), result.failure[:base]
  end

  test "find_and_validate_user_admin fails when the user is not an admin" do
    result = @operation.call(:find_and_validate_user_admin, create(:user).id)

    assert_predicate result, :failure?
    assert_equal I18n.t("operations.base.user_is_not_admin"), result.failure[:base]
  end

  test "find_and_validate_user_admin succeeds for an admin" do
    admin = create(:user, :admin)
    result = @operation.call(:find_and_validate_user_admin, admin.id)

    assert_predicate result, :success?
    assert_equal admin, result.value!
  end

  test "delete_user_on_database fails when the record cannot be destroyed" do
    user = create(:user)
    user.stubs(:destroy).returns(false)
    user.errors.add(:base, I18n.t("errors.messages.invalid"))

    result = @operation.call(:delete_user_on_database, user)

    assert_predicate result, :failure?
    assert_includes result.failure[:base], I18n.t("errors.messages.invalid")
  end

  test "delete_user_on_database succeeds and removes the user" do
    user = create(:user)
    result = nil

    assert_difference -> { User.count }, -1 do
      result = @operation.call(:delete_user_on_database, user)
    end

    assert_predicate result, :success?
  end
end
