# frozen_string_literal: true

require "test_helper"

module Admin
  class DashboardDecoratorTest < ActiveSupport::TestCase
    setup do
      create(:user, :admin)
      @decorator = DashboardDecorator.new
    end

    test "counts no users when the database is empty" do
      decorator = DashboardDecorator.new(user_repo: User.none)

      assert_equal 0, decorator.total_users
      assert_equal 0.0, decorator.admins_percentage
    end

    test "counts the users of each role" do
      create_list(:user, 3)

      assert_equal 4, @decorator.total_users
      assert_equal 1, @decorator.admins_count
      assert_equal 3, @decorator.profiles_count
    end

    test "calculates the percentage of each role" do
      create_list(:user, 3)

      assert_equal 25.0, @decorator.admins_percentage
      assert_equal 75.0, @decorator.profiles_percentage
    end
  end
end
