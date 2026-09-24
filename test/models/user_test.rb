# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @validations = Rails.configuration.x.validations
  end

  test "the factory builds a valid user" do
    assert_predicate build(:user), :valid?
  end

  test "downcases and strips email" do
    user = User.new(email: " DOWNCASED@EXAMPLE.COM ")

    assert_equal "downcased@example.com", user.email
  end

  test "requires a full name" do
    user = build(:user, full_name: "")

    assert_not user.valid?
    assert_includes user.errors.details[:full_name], {error: :blank}
  end

  test "requires the full name length to be within the limits" do
    length = @validations.full_name_length

    assert_not build(:user, full_name: "a" * (length.min - 1)).valid?
    assert_not build(:user, full_name: "a" * (length.max + 1)).valid?
    assert_predicate build(:user, full_name: "a" * length.min), :valid?
    assert_predicate build(:user, full_name: "a" * length.max), :valid?
  end

  test "requires an email" do
    user = build(:user, email: "")

    assert_not user.valid?
    assert_includes user.errors.details[:email], {error: :blank}
  end

  test "rejects a malformed email" do
    %w[invalid a@b user@@example.com].each do |email|
      assert_not build(:user, email:).valid?, "#{email} should be invalid"
    end
  end

  test "requires a unique email, compared after normalization" do
    create(:user, email: "jane@example.com")
    user = build(:user, email: " JANE@example.com ")

    assert_not user.valid?
    assert_includes user.errors.details[:email].pluck(:error), :taken
  end

  test "requires the password length to be within the limits" do
    length = @validations.password_length

    assert_not build(:user, password: "a" * (length.min - 1)).valid?
    assert_not build(:user, password: "a" * (length.max + 1)).valid?
    assert_predicate build(:user, password: "a" * length.min), :valid?
  end

  test "does not require the password again once persisted" do
    user = User.find(create(:user).id)

    assert_predicate user, :valid?
  end

  test "requires the password confirmation to match" do
    user = build(:user, password: "password", password_confirmation: "another-password")

    assert_not user.valid?
    assert_includes user.errors.details[:password_confirmation].pluck(:error), :confirmation
  end

  test "authenticates with the right password only" do
    user = create(:user, password: "password")

    assert_equal user, user.authenticate("password")
    assert_not user.authenticate("wrong-password")
  end

  test "is a profile by default and an admin with the admin trait" do
    assert_predicate build(:user), :profile?
    assert_predicate build(:user, :admin), :admin?
  end

  test "rejects an unknown role without raising" do
    user = build(:user, role: "owner")

    assert_not user.valid?
    assert_includes user.errors.details[:role].pluck(:error), :inclusion
  end

  test "with_role keeps only the users of the role" do
    admin = create(:user, :admin)
    create(:user)

    assert_equal [admin], User.with_role("admin").to_a
  end

  test "with_role ignores an unknown or missing role" do
    create_list(:user, 2)

    assert_equal 2, User.with_role("owner").count
    assert_equal 2, User.with_role(nil).count
  end

  test "search matches the name or the email" do
    jane = create(:user, full_name: "Jane Cooper", email: "jane@example.com")
    wade = create(:user, full_name: "Wade Warren", email: "wade@acme.test")

    assert_equal [jane], User.search(" cooper ").to_a
    assert_equal [wade], User.search("acme").to_a
  end

  test "search ignores a blank query" do
    create_list(:user, 2)

    assert_equal 2, User.search("").count
    assert_equal 2, User.search(nil).count
  end

  test "lists the sessions from the newest to the oldest" do
    user = create(:user)
    older = user.sessions.create!(created_at: 2.days.ago)
    newer = user.sessions.create!(created_at: 1.hour.ago)

    assert_equal [newer, older], user.sessions.to_a
  end

  test "destroys the sessions with the user" do
    user = create(:user)
    user.sessions.create!

    assert_difference("Session.count", -1) { user.destroy }
  end

  test "destroys the imports with the user" do
    import = create(:import)

    assert_difference("Import.count", -1) { import.user.destroy }
  end

  test "accepts a png avatar" do
    user = build(:user)
    user.avatar_image.attach(fixture_file_upload("avatar.png", "image/png"))

    assert_predicate user, :valid?
  end

  test "rejects an avatar that is not an image" do
    user = build(:user)
    user.avatar_image.attach(fixture_file_upload("users.csv", "text/csv"))

    assert_not user.valid?
    assert_predicate user.errors[:avatar_image], :any?
  end

  test "rejects an avatar larger than 5 MB" do
    png = file_fixture("avatar.png").binread
    user = build(:user)
    user.avatar_image.attach(
      io: StringIO.new(png + ("0" * 5.megabytes)), filename: "big.png", content_type: "image/png"
    )

    assert_not user.valid?
    assert_predicate user.errors[:avatar_image], :any?
  end

  test "defines the avatar variants" do
    variants = User.reflect_on_attachment(:avatar_image).named_variants.keys

    assert_equal %i[thumb medium large], variants
  end
end
