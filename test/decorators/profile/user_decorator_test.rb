# frozen_string_literal: true

require "test_helper"

module Profile
  class UserDecoratorTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @decorator = UserDecorator.new(@user)
    end

    test "exposes the declared attributes" do
      assert_equal({id: @user.id, full_name: @user.full_name, email: @user.email}, @decorator.to_h)
    end

    test "builds the initials" do
      assert_equal "JC", UserDecorator.new(build(:user, full_name: "Jane Cooper")).initials
    end

    test "translates the role" do
      assert_equal I18n.t("decorators.user.roles.profile"), @decorator.role_label
    end

    test "formats the date the user became a member" do
      assert_equal I18n.l(@user.created_at.to_date, format: :long), @decorator.member_since
    end

    test "returns the avatar variant when there is an image attached" do
      @user.avatar_image.attach(fixture_file_upload("avatar.png", "image/png"))

      assert_not_nil @decorator.avatar_variant(:large)
    end
  end
end
