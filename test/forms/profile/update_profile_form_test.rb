# frozen_string_literal: true

require "test_helper"

module Profile
  class UpdateProfileFormTest < ActiveSupport::TestCase
    setup do
      @user = create(:user, full_name: "Jane Cooper", email: "jane@example.com")
    end

    test "is named User, so form_with generates user fields" do
      assert_equal "user", UpdateProfileForm.model_name.param_key
    end

    test "prefills the fields from the user" do
      form = UpdateProfileForm.new(user: @user)

      assert_equal "Jane Cooper", form.full_name
      assert_equal "jane@example.com", form.email
      assert_equal @user, form.user
    end

    test "keeps the submitted values over the ones of the user" do
      form = UpdateProfileForm.new(user: @user, full_name: "New Name")

      assert_equal "New Name", form.full_name
    end

    test "casts the avatar removal checkbox" do
      form = UpdateProfileForm.new(remove_avatar_image: "1")

      assert_equal true, form.attributes["remove_avatar_image"]
    end

    test "fails when attributes are blank and copies the field errors" do
      form = UpdateProfileForm.new(full_name: "", email: "")

      assert_not form.submit(@user.id)
      assert_includes form.errors[:full_name], I18n.t("contracts.errors.key?")
      assert_includes form.errors[:email], I18n.t("contracts.errors.key?")
    end

    test "copies operation errors to base when the user is not found" do
      form = UpdateProfileForm.new(full_name: "Jane", email: "jane@example.com")

      assert_not form.submit(nil)
      assert_includes form.errors[:base], I18n.t("operations.base.user_not_found")
    end

    test "fails when the email already belongs to another user" do
      create(:user, email: "taken@example.com")
      form = UpdateProfileForm.new(full_name: "Jane Cooper", email: "taken@example.com")

      assert_not form.submit(@user.id)
      assert_includes form.errors[:email], I18n.t("errors.messages.taken")
    end

    test "succeeds, updates the profile and exposes the user" do
      form = UpdateProfileForm.new(full_name: "Jane C.", email: "jane.c@example.com")

      assert form.submit(@user.id)
      assert_equal "Jane C.", @user.reload.full_name
      assert_equal @user, form.user
      assert_empty form.errors
    end

    test "sends the user id and the attributes to the operation" do
      Profile::UpdateProfileOperation
        .expects(:call)
        .with(@user.id, has_entries("full_name" => "Jane C.", "email" => "jane.c@example.com"))

      UpdateProfileForm.new(full_name: "Jane C.", email: "jane.c@example.com").submit(@user.id)
    end
  end
end
