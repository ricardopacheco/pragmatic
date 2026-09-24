# frozen_string_literal: true

require "test_helper"

module Admin
  class UserDecoratorTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @decorator = UserDecorator.new(@user)
    end

    test "exposes the declared attributes" do
      assert_equal(
        {id: @user.id, full_name: @user.full_name, email: @user.email, role: "profile"},
        @decorator.to_h
      )
    end

    test "delegates what it does not define" do
      assert_predicate @decorator, :profile?
    end

    test "builds the initials of the first and last name" do
      assert_equal "JC", UserDecorator.new(build(:user, full_name: "Jane Cooper")).initials
    end

    test "builds the initials of a single name" do
      assert_equal "J", UserDecorator.new(build(:user, full_name: "Jane")).initials
    end

    test "has no avatar variant when there is no image attached" do
      assert_not_predicate @decorator, :avatar?
      assert_nil @decorator.avatar_variant
    end

    test "returns the avatar variant when there is an image attached" do
      @user.avatar_image.attach(fixture_file_upload("avatar.png", "image/png"))

      assert_predicate @decorator, :avatar?
      assert_kind_of ActiveStorage::VariantWithRecord, @decorator.avatar_variant
      assert_equal @user.avatar_image.variant(:medium).variation.transformations,
        @decorator.avatar_variant(:medium).variation.transformations
    end

    test "translates the role of a regular user" do
      assert_equal I18n.t("decorators.user.roles.profile"), @decorator.role_label
      assert_equal "badge-ghost", @decorator.role_badge_class
    end

    test "translates the role of an admin" do
      decorator = UserDecorator.new(create(:user, :admin))

      assert_equal I18n.t("decorators.user.roles.admin"), decorator.role_label
      assert_equal "badge-soft badge-primary", decorator.role_badge_class
    end

    test "translates the role in the current locale" do
      I18n.with_locale(:pt) do
        assert_equal "Usuário", @decorator.role_label
      end
    end

    test "formats the date the user joined" do
      assert_equal I18n.l(@user.created_at.to_date, format: :long), @decorator.joined_at
    end

    test "builds the dom id used by the turbo streams" do
      assert_equal "user_#{@user.id}", @decorator.dom_id
    end

    test "wraps a collection" do
      other = create(:user)

      assert_equal [@user.full_name, other.full_name], UserDecorator.wrap(User.order(:created_at)).map(&:full_name)
    end
  end
end
