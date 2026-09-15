# frozen_string_literal: true

module Admin
  class DashboardDecorator
    attr_reader :current_user

    def initialize(current_user, user_repo: ::User)
      @current_user = current_user
      @user_repo = user_repo
    end

    def total_users
      @total_users ||= counts_by_role.values.sum
    end

    def any_users?
      total_users.positive?
    end

    def admins_count
      counts_by_role.fetch("admin", 0)
    end

    def profiles_count
      counts_by_role.fetch("profile", 0)
    end

    def admins_percentage
      percentage_of(admins_count)
    end

    def profiles_percentage
      percentage_of(profiles_count)
    end

    private

    attr_reader :user_repo

    # Single query for every counter of the dashboard.
    def counts_by_role
      @counts_by_role ||= user_repo.group(:role).count
    end

    def percentage_of(count)
      return 0.0 if total_users.zero?

      ((count / total_users.to_f) * 100).round(1)
    end
  end
end
