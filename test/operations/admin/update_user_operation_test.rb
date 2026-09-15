# frozen_string_literal: true

require "test_helper"

module Admin
  class UpdateUserOperationTest < ActiveSupport::TestCase
    setup do
      @operation = UpdateUserOperation.new
      @admin = create(:user, :admin)
      @user = create(:user, email: "jane@example.com", password: "password")
    end

    test "fails when the admin does not exist" do
      result = @operation.call(nil, @user.id, valid_attributes)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.admin_not_found"), result.failure[:base]
    end

    test "fails when the user is not an admin" do
      result = @operation.call(create(:user).id, @user.id, valid_attributes)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_is_not_admin"), result.failure[:base]
    end

    test "fails when the edited user does not exist" do
      result = @operation.call(@admin.id, nil, valid_attributes)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
    end

    test "fails when attributes are blank" do
      result = @operation.call(@admin.id, @user.id, {full_name: "", email: "", role: ""})

      assert_predicate result, :failure?
      assert_includes result.failure[:full_name], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:role], I18n.t("contracts.errors.key?")
    end

    test "fails when the email already belongs to another user" do
      result = @operation.call(@admin.id, @user.id, valid_attributes.merge(email: @admin.email))

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("errors.messages.taken")
    end

    test "fails with the model errors when the record cannot be saved" do
      User.any_instance.stubs(:update).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:full_name, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      result = @operation.call(@admin.id, @user.id, valid_attributes)

      assert_predicate result, :failure?
      assert_includes result.failure[:full_name], I18n.t("errors.messages.invalid")
    end

    test "does not change the user when the operation fails" do
      assert_no_changes -> { @user.reload.full_name } do
        @operation.call(@admin.id, @user.id, {full_name: "", email: "", role: ""})
      end
    end

    test "succeeds and updates the user" do
      result = @operation.call(@admin.id, @user.id, valid_attributes.merge(role: "admin"))

      assert_predicate result, :success?
      assert_equal "Jane Cooper", @user.reload.full_name
      assert_predicate @user, :admin?
    end

    test "keeps the current password when no password is sent" do
      @operation.call(@admin.id, @user.id, valid_attributes)

      assert @user.reload.authenticate("password")
    end

    test "changes the password when one is sent" do
      attributes = valid_attributes.merge(password: "new-password", password_confirmation: "new-password")
      @operation.call(@admin.id, @user.id, attributes)

      assert @user.reload.authenticate("new-password")
    end

    test "removes the current avatar when asked" do
      @user.avatar_image.attach(fixture_file_upload("avatar.png", "image/png"))

      result = @operation.call(@admin.id, @user.id, valid_attributes.merge(remove_avatar_image: "1"))

      assert_predicate result, :success?
      assert_enqueued_with(job: ActiveStorage::PurgeJob)
    end

    private

    def valid_attributes
      {full_name: "Jane Cooper", email: @user.email, role: "profile"}
    end
  end
end
