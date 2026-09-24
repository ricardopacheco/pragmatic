# frozen_string_literal: true

require "test_helper"

module Admin
  class UpdateUserFormTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user, :admin)
      @user = create(:user)
    end

    test "prefills the fields from the user, role included" do
      form = UpdateUserForm.new(user: @user)

      assert_equal @user.full_name, form.full_name
      assert_equal @user.email, form.email
      assert_equal "profile", form.role
    end

    test "keeps the submitted values over the ones of the user" do
      form = UpdateUserForm.new(user: @user, role: "admin")

      assert_equal "admin", form.role
    end

    test "fails when attributes are blank and copies the field errors" do
      form = UpdateUserForm.new(full_name: "", email: "", role: "")

      assert_not form.submit(@admin.id, @user.id)
      assert_includes form.errors[:full_name], I18n.t("contracts.errors.key?")
      assert_includes form.errors[:role], I18n.t("contracts.errors.key?")
    end

    test "copies operation errors to base when the user is not found" do
      form = UpdateUserForm.new(valid_attributes)

      assert_not form.submit(@admin.id, nil)
      assert_includes form.errors[:base], I18n.t("operations.base.user_not_found")
    end

    test "fails when the email already belongs to another user" do
      form = UpdateUserForm.new(valid_attributes.merge(email: @admin.email))

      assert_not form.submit(@admin.id, @user.id)
      assert_includes form.errors[:email], I18n.t("errors.messages.taken")
    end

    test "succeeds, updates the user and exposes it" do
      form = UpdateUserForm.new(valid_attributes.merge(role: "admin"))

      assert form.submit(@admin.id, @user.id)
      assert_predicate @user.reload, :admin?
      assert_equal @user, form.user
    end

    test "keeps the current password when none is sent" do
      UpdateUserForm.new(valid_attributes).submit(@admin.id, @user.id)

      assert @user.reload.authenticate("password")
    end

    test "sends the admin id, the user id and the attributes to the operation" do
      Admin::UpdateUserOperation.expects(:call).with(@admin.id, @user.id, has_entries("role" => "profile"))

      UpdateUserForm.new(valid_attributes).submit(@admin.id, @user.id)
    end

    private

    def valid_attributes
      {full_name: "Jane Cooper", email: "jane@example.com", role: "profile"}
    end
  end
end
