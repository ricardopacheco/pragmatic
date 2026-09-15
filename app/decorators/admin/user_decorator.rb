# frozen_string_literal: true

module Admin
  class UserDecorator < Burgundy::Item
    include UserPresentation

    attributes :id, :full_name, :email, :role

    def role_badge_class
      item.admin? ? "badge-soft badge-primary" : "badge-ghost"
    end

    def joined_at
      l(item.created_at.to_date, format: :long)
    end
  end
end
