# frozen_string_literal: true

require "test_helper"

class ApplicationContractTest < ActiveSupport::TestCase
  class SampleContract < ApplicationContract
    params do
      optional(:full_name).filled(:string)
      optional(:email).filled(:string)
      optional(:password).filled(:string)
      optional(:password_confirmation).filled(:string)
    end

    rule(:full_name).validate(:full_name_format)
    rule(:email).validate(:email_format)
    rule(:password).validate(:password_format)
    rule(:password, :password_confirmation).validate(:password_confirmation)
  end

  setup do
    @contract = SampleContract.new
    @full_name_length = Rails.configuration.x.validations.full_name_length
    @password_length = Rails.configuration.x.validations.password_length
  end

  test "full_name_format fails when the name is shorter than the minimum" do
    result = @contract.call(full_name: "A" * (@full_name_length.min - 1))

    assert_predicate result, :failure?
    assert_includes result.errors[:full_name], full_name_format_message
  end

  test "full_name_format fails when the name is longer than the maximum" do
    result = @contract.call(full_name: "A" * (@full_name_length.max + 1))

    assert_predicate result, :failure?
    assert_includes result.errors[:full_name], full_name_format_message
  end

  test "email_format fails when the email has an invalid format" do
    result = @contract.call(email: "invalid_email")

    assert_predicate result, :failure?
    assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
  end

  test "email_format fails when the email has no top-level domain" do
    result = @contract.call(email: "user@localhost")

    assert_predicate result, :failure?
    assert_includes result.errors[:email], I18n.t("contracts.errors.custom.macro.email_format")
  end

  test "password_format fails when the password is shorter than the minimum" do
    result = @contract.call(password: "a" * (@password_length.min - 1))

    assert_predicate result, :failure?
    assert_includes result.errors[:password], password_format_message
  end

  test "password_format fails when the password is longer than the maximum" do
    result = @contract.call(password: "a" * (@password_length.max + 1))

    assert_predicate result, :failure?
    assert_includes result.errors[:password], password_format_message
  end

  test "password_confirmation fails when the confirmation does not match" do
    result = @contract.call(password: "password", password_confirmation: "different")

    assert_predicate result, :failure?
    assert_includes result.errors[:password_confirmation], password_confirmation_message
  end

  test "password_confirmation is skipped when the password is already invalid" do
    result = @contract.call(password: "short", password_confirmation: "different")

    assert_predicate result, :failure?
    assert_nil result.errors[:password_confirmation]
  end

  test "macros skip optional keys that were not sent" do
    result = @contract.call({})

    assert_predicate result, :success?
    assert_empty result.errors
  end

  test "succeeds when all values are valid" do
    result = @contract.call(
      full_name: "João da Silva", email: "joao@example.com", password: "password", password_confirmation: "password"
    )

    assert_predicate result, :success?
    assert_empty result.errors
  end

  private

  def full_name_format_message
    I18n.t("contracts.errors.custom.macro.full_name_format", min: @full_name_length.min, max: @full_name_length.max)
  end

  def password_format_message
    I18n.t("contracts.errors.custom.macro.password_format", min: @password_length.min, max: @password_length.max)
  end

  def password_confirmation_message
    I18n.t("errors.messages.confirmation", attribute: User.human_attribute_name(:password))
  end
end
