# frozen_string_literal: true

require "test_helper"

module Profile
  class UpdateProfileOperationTest < ActiveSupport::TestCase
    setup do
      @operation = UpdateProfileOperation.new
      @user = create(:user, email: "jane@example.com")
    end

    test "fails when the user does not exist" do
      result = @operation.call(nil, valid_attributes)

      assert_predicate result, :failure?
      assert_equal I18n.t("operations.base.user_not_found"), result.failure[:base]
    end

    test "fails when attributes are blank" do
      result = @operation.call(@user.id, {full_name: "", email: ""})

      assert_predicate result, :failure?
      assert_includes result.failure[:full_name], I18n.t("contracts.errors.key?")
      assert_includes result.failure[:email], I18n.t("contracts.errors.key?")
    end

    test "fails when the email already belongs to another user" do
      create(:user, email: "taken@example.com")
      result = @operation.call(@user.id, valid_attributes.merge(email: "taken@example.com"))

      assert_predicate result, :failure?
      assert_includes result.failure[:email], I18n.t("errors.messages.taken")
    end

    test "fails with the model errors when the record cannot be saved" do
      User.any_instance.stubs(:update).returns(false)
      errors = ActiveModel::Errors.new(User.new)
      errors.add(:full_name, I18n.t("errors.messages.invalid"))
      User.any_instance.stubs(:errors).returns(errors)

      result = @operation.call(@user.id, valid_attributes)

      assert_predicate result, :failure?
      assert_includes result.failure[:full_name], I18n.t("errors.messages.invalid")
    end

    test "does not change the user when the operation fails" do
      assert_no_changes -> { @user.reload.full_name } do
        @operation.call(@user.id, {full_name: "", email: ""})
      end
    end

    test "succeeds and updates the profile" do
      result = @operation.call(@user.id, valid_attributes)

      assert_predicate result, :success?
      assert_equal "Jane Cooper", @user.reload.full_name
      assert_equal "jane.cooper@example.com", @user.email
    end

    test "succeeds and attaches a new avatar image" do
      result = @operation.call(@user.id, valid_attributes.merge(avatar_image: avatar_upload))

      assert_predicate result, :success?
      assert_predicate @user.reload.avatar_image, :attached?
    end

    test "removes the current avatar when asked" do
      @user.avatar_image.attach(avatar_upload)

      result = @operation.call(@user.id, valid_attributes.merge(remove_avatar_image: "1"))

      assert_predicate result, :success?
      assert_enqueued_with(job: ActiveStorage::PurgeJob)
    end

    test "keeps the new avatar when the removal is sent together with a file" do
      @user.avatar_image.attach(avatar_upload)

      result = @operation.call(
        @user.id, valid_attributes.merge(avatar_image: avatar_upload, remove_avatar_image: "1")
      )

      assert_predicate result, :success?
      assert_predicate @user.reload.avatar_image, :attached?
    end

    test "enqueues the broadcast job" do
      assert_enqueued_with(job: Profile::UpdateProfileBroadcastJob, queue: "broadcast") do
        @operation.call(@user.id, valid_attributes)
      end
    end

    private

    def valid_attributes
      {full_name: "Jane Cooper", email: "jane.cooper@example.com"}
    end

    def avatar_upload
      fixture_file_upload("avatar.png", "image/png")
    end
  end
end
