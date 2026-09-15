# frozen_string_literal: true

module Admin
  class UsersPresenter < ApplicationPresenter
    def render_users
      return render_partial_path(partial: "admin/users/empty") if users.empty?

      render_partial_path(partial: "admin/users/table", locals: {users:})
    end

    private

    def users
      options.fetch(:users, [])
    end
  end
end
