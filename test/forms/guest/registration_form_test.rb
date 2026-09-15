# frozen_string_literal: true

require "test_helper"

module Guest
  class RegistrationFormTest < ActiveSupport::TestCase
    test "is named User, so form_with generates user fields" do
      assert_equal "user", RegistrationForm.model_name.param_key
    end

    test "fails when attributes are blank and copies the field errors" do
      form = RegistrationForm.new

      assert_not form.submit
      assert_includes form.errors[:full_name].first, I18n.t("contracts.errors.key?")
      assert_includes form.errors[:email].first, I18n.t("contracts.errors.key?")
    end

    test "fails when the email is already taken" do
      create(:user, email: "taken@example.com")
      form = RegistrationForm.new(valid_attributes.merge(email: "taken@example.com"))

      assert_not form.submit
      assert_includes form.errors[:email], I18n.t("errors.messages.taken")
    end

    test "does not create a user when it fails" do
      assert_no_difference -> { User.count } do
        RegistrationForm.new.submit
      end
    end

    test "succeeds, creates the user and exposes it" do
      form = RegistrationForm.new(valid_attributes)
      created = nil

      assert_difference -> { User.count }, 1 do
        created = form.submit
      end

      assert created
      assert_predicate form.user, :profile?
      assert_empty form.errors
    end

    test "accepts an avatar image" do
      form = RegistrationForm.new(valid_attributes.merge(avatar_image: fixture_file_upload("avatar.png", "image/png")))

      assert form.submit
      assert_predicate form.user.avatar_image, :attached?
    end

    private

    def valid_attributes
      {
        full_name: "Jane Cooper",
        email: "jane@example.com",
        password: "password",
        password_confirmation: "password"
      }
    end
  end
end
