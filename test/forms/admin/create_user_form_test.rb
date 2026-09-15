# frozen_string_literal: true

require "test_helper"

module Admin
  class CreateUserFormTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
    end

    test "is named User, so form_with generates user fields" do
      assert_equal "user", CreateUserForm.model_name.param_key
    end

    test "fails when attributes are blank and copies the field errors" do
      form = CreateUserForm.new

      assert_not form.submit(@admin.id)
      assert_includes form.errors[:full_name], I18n.t("contracts.errors.key?")
      assert_includes form.errors[:role], I18n.t("contracts.errors.key?")
    end

    test "copies operation errors to base when the admin is not found" do
      form = CreateUserForm.new(valid_attributes)

      assert_not form.submit(nil)
      assert_includes form.errors[:base], I18n.t("operations.base.admin_not_found")
    end

    test "fails when the email is already taken" do
      create(:user, email: "taken@example.com")
      form = CreateUserForm.new(valid_attributes.merge(email: "taken@example.com"))

      assert_not form.submit(@admin.id)
      assert_includes form.errors[:email], I18n.t("errors.messages.taken")
    end

    test "does not create a user when it fails" do
      assert_no_difference -> { User.count } do
        CreateUserForm.new.submit(@admin.id)
      end
    end

    test "succeeds, creates the user and exposes it" do
      form = CreateUserForm.new(valid_attributes.merge(role: "admin"))
      created = nil

      assert_difference -> { User.count }, 1 do
        created = form.submit(@admin.id)
      end

      assert created
      assert_predicate form.user, :admin?
      assert_empty form.errors
    end

    test "sends the admin id and the attributes to the operation" do
      Admin::CreateUserOperation.expects(:call).with(@admin.id, has_entries("email" => "jane@example.com"))

      CreateUserForm.new(valid_attributes).submit(@admin.id)
    end

    private

    def valid_attributes
      {
        full_name: "Jane Cooper",
        email: "jane@example.com",
        role: "profile",
        password: "password",
        password_confirmation: "password"
      }
    end
  end
end
