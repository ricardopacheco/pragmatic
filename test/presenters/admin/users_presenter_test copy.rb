# frozen_string_literal: true

require "test_helper"

module Admin
  class UsersPresenterTest < ActiveSupport::TestCase
    setup do
      @view_context = mock("view_context")
      @admin = build(:user, :admin)
    end

    test "renders the empty state when there are no users" do
      @view_context.expects(:render).with({partial: "admin/users/empty"}).returns("empty")

      presenter = UsersPresenter.new(@view_context, @admin, users: [])

      assert_equal "empty", presenter.render_users
    end

    test "renders the empty state when no collection is given" do
      @view_context.expects(:render).with({partial: "admin/users/empty"}).returns("empty")

      presenter = UsersPresenter.new(@view_context, @admin)

      assert_equal "empty", presenter.render_users
    end

    test "renders the table with the decorated users" do
      users = Admin::UserDecorator.wrap([build(:user)])
      @view_context.expects(:render).with({partial: "admin/users/table", locals: {users:}}).returns("table")

      presenter = UsersPresenter.new(@view_context, @admin, users:)

      assert_equal "table", presenter.render_users
    end

    test "keeps the current user" do
      assert_equal @admin, UsersPresenter.new(@view_context, @admin).current_user
    end
  end
end
